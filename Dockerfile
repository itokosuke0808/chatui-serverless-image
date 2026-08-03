FROM runpod/comfyui:cuda12.8

RUN apt-get update -qq && apt-get install -y -qq zstd pciutils unzip nginx && \
    curl -fsSL https://ollama.com/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir \
    segment-anything scikit-image piexif transformers \
    opencv-python-headless scipy numpy dill matplotlib \
    "ultralytics>=8.3.162"

COPY nginx-health-proxy.conf /etc/nginx/sites-enabled/ollama-proxy.conf
RUN rm -f /etc/nginx/sites-enabled/default

COPY start.sh /start.sh
RUN chmod +x /start.sh
