#!/bin/bash
OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS='*' OLLAMA_MODELS=/workspace/ollama-models OLLAMA_CONTEXT_LENGTH=4096 nohup ollama serve > /workspace/ollama.log 2>&1 &
exec /start.sh
