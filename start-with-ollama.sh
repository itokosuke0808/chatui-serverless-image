#!/bin/bash
(
  # 永続ボリュームのマウントが完了する（/workspace/ollama-modelsに中身が現れる）まで待つ。
  # マウント前の空の/workspaceにollama serveが書き込んでしまうと、後からマウントされた
  # 本物のボリュームに隠れて見えなくなる（原因調査で判明した現象への対策）
  for i in $(seq 1 30); do
    if [ -d /workspace/ollama-models ] && [ -n "$(ls -A /workspace/ollama-models 2>/dev/null)" ]; then
      break
    fi
    sleep 2
  done
  for i in 1 2 3 4 5; do
    OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS='*' OLLAMA_MODELS=/workspace/ollama-models OLLAMA_CONTEXT_LENGTH=4096 ollama serve >> /workspace/ollama.log 2>&1
    echo "ollama serve exited (attempt $i), retrying in 3s..." >> /workspace/ollama.log
    sleep 3
  done
) &
exec /start.sh
