#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

DEBUG_LOG_FALLBACK=/tmp/debug-timing.log
log_ts() {
  local msg="[$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)] $1"
  echo "$msg"
  echo "$msg" >> "$DEBUG_LOG_FALLBACK"
  echo "$msg" >> /workspace-debug-timing.log 2>/dev/null || true
}

log_ts "script start"

# 重要: ServerlessワーカーではネットワークボリュームはPodと違い /runpod-volume に
# マウントされる（Podでは/workspace）。/workspace を /runpod-volume への別名にして、
# 以降 /workspace を参照するだけで永続ボリュームに向くようにする。
if [ -d /runpod-volume ]; then
  cd /
  if [ -d /workspace ] && [ ! -L /workspace ]; then
    rm -rf /workspace
  fi
  ln -sfn /runpod-volume /workspace
  mkdir -p /workspace/runpod-slim
  cd /workspace/runpod-slim
fi
log_ts "volume symlink done"

# nginxを起動（11434で待ち受け、/pingだけその場で200を返し、それ以外は
# 11435番のOllama本体へ中継する。RunPod側のHEALTH_CHECK_PATH環境変数が
# この環境では効かなかったため、Ollama側でなくnginx側でヘルスチェックに応答する）
nginx
log_ts "nginx started (health check now respondable)"

# 永続ボリュームのマウント完了を待つ
for i in $(seq 1 30); do
  if [ -d /workspace/ollama-models ] && [ -n "$(ls -A /workspace/ollama-models 2>/dev/null)" ]; then
    log_ts "volume mount confirmed after $i checks"
    break
  fi
  sleep 2
done

MODEL_SIZE=$(du -sh /workspace/ollama-models 2>/dev/null | cut -f1)
log_ts "ollama-models dir size: ${MODEL_SIZE:-unknown}"

log_ts "invoking ollama serve"

# バックグラウンドでOllama本体(11435)が実際に応答し始めた瞬間をログに残す
(
  for i in $(seq 1 150); do
    if curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:11435/api/version 2>/dev/null | grep -q 200; then
      log_ts "ollama backend (11435) responding to /api/version after $i checks"
      break
    fi
    sleep 1
  done
) &

# テキスト専用ワーカーなので、Ollamaをそのままフォアグラウンドで実行し続ける
# （ComfyUIは起動しない。落ちたら数秒待って再起動する）
for i in 1 2 3 4 5; do
  OLLAMA_HOST=0.0.0.0:11435 OLLAMA_ORIGINS='*' OLLAMA_MODELS=/workspace/ollama-models OLLAMA_CONTEXT_LENGTH=4096 ollama serve >> /workspace/ollama.log 2>&1
  log_ts "ollama serve exited (attempt $i), retrying in 3s..."
  sleep 3
done

log_ts "Ollama failed to stay up after 5 attempts. See /workspace/ollama.log"
sleep infinity
