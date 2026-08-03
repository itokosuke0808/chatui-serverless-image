#!/bin/bash
(
  for i in 1 2 3 4 5; do
    OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS='*' OLLAMA_MODELS=/workspace/ollama-models OLLAMA_CONTEXT_LENGTH=4096 ollama serve >> /workspace/ollama.log 2>&1
    echo "ollama serve exited (attempt $i), retrying in 3s..." >> /workspace/ollama.log
    sleep 3
  done
) &
exec /start.sh
