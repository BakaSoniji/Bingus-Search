# Multi-stage build: Download models in build stage
FROM python:3.12-slim AS model-downloader

WORKDIR /tmp/model-download

# Install dependencies for model download
COPY ./requirements/ ./requirements/
RUN pip install --no-cache-dir -r ./requirements/torch-cpu-runtime.txt
RUN pip install --no-cache-dir -r ./requirements/runtime.txt

# Copy and run model download script
COPY download_models.py .
RUN python download_models.py

# Production stage
FROM python:3.12-slim

WORKDIR /usr/src/app

# curl is needed for healthcheck
RUN apt update && apt install -y curl && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install dependencies
COPY ./requirements/ ./requirements/
RUN pip install --no-cache-dir -r ./requirements/torch-cpu-runtime.txt
RUN pip install --no-cache-dir -r ./requirements/runtime.txt

# Copy application code
COPY . .

# Copy pre-downloaded models from build stage
COPY --from=model-downloader /bundled-models /usr/src/app/bundled-models

# Set environment variable to use bundled models as primary cache
ENV SENTENCE_TRANSFORMERS_HOME=/usr/src/app/bundled-models

CMD ["python", "./encoder-uvicorn.py"]
