#!/bin/bash
set -e

log_ts() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)] $1"
}

# 永続ボリュームに依存しない構成。モデルはHuggingFace Hub（非公開リポジトリ）
# から直接ダウンロードする。これによりデータセンターを問わずデプロイできる。
MODEL_REPO="${MODEL_REPO:-itowww/mistral-rp-gptq-4bit}"
SERVED_NAME="${SERVED_NAME:-gptq-mistral-rp}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-4096}"
GPU_MEM_UTIL="${GPU_MEM_UTIL:-0.90}"

log_ts "starting vLLM: model=$MODEL_REPO max_model_len=$MAX_MODEL_LEN gpu_mem_util=$GPU_MEM_UTIL"

exec python3 -m vllm.entrypoints.openai.api_server \
  --model "$MODEL_REPO" \
  --served-model-name "$SERVED_NAME" \
  --port 8000 \
  --gpu-memory-utilization "$GPU_MEM_UTIL" \
  --max-model-len "$MAX_MODEL_LEN"
