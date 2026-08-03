#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

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

# nginxを起動（11434で待ち受け、/pingだけその場で200を返し、それ以外は
# 11435番のOllama本体へ中継する。RunPod側のHEALTH_CHECK_PATH環境変数が
# この環境では効かなかったため、Ollama側でなくnginx側でヘルスチェックに応答する）
nginx

# 永続ボリュームのマウント完了を待つ
for i in $(seq 1 30); do
  if [ -d /workspace/ollama-models ] && [ -n "$(ls -A /workspace/ollama-models 2>/dev/null)" ]; then
    break
  fi
  sleep 2
done

# テキスト専用ワーカーなので、Ollamaをそのままフォアグラウンドで実行し続ける
# （ComfyUIは起動しない。落ちたら数秒待って再起動する）
for i in 1 2 3 4 5; do
  OLLAMA_HOST=0.0.0.0:11435 OLLAMA_ORIGINS='*' OLLAMA_MODELS=/workspace/ollama-models OLLAMA_CONTEXT_LENGTH=4096 ollama serve >> /workspace/ollama.log 2>&1
  echo "ollama serve exited (attempt $i), retrying in 3s..." >> /workspace/ollama.log
  sleep 3
done

echo "Ollama failed to stay up after 5 attempts. See /workspace/ollama.log"
sleep infinity
