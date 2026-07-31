FROM runpod/comfyui:cuda12.8

RUN apt-get update -qq && apt-get install -y -qq zstd pciutils unzip && \
    curl -fsSL https://ollama.com/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir \
    segment-anything scikit-image piexif transformers \
    opencv-python-headless scipy numpy dill matplotlib \
    "ultralytics>=8.3.162"

COPY start-with-ollama.sh /start-with-ollama.sh
RUN chmod +x /start-with-ollama.sh

ENTRYPOINT ["/start-with-ollama.sh"]
