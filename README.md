# Bingus

## Release Process (CalVer + Cloudflare)

This fork uses a simple, automated release pipeline:

- Versioning: CalVer `vYYYY.MM.P` (e.g., `v2025.08.0`), auto-incremented on each push to `main`.
- Pipeline: On push to `main`, GitHub Actions will:
  - Build and push containers for `encoder`, `api`, and `bot` with tags `latest` and `vYYYY.MM.P`.
  - Update and package the Helm chart (`helm/`) with the same CalVer version and publish to OCI.
  - Create a GitHub Release with a generated changelog.
  - Optionally deploy the frontend to Cloudflare R2 (enable via repo variable `ENABLE_FRONTEND_DEPLOYMENT=true`).

### Configure Cloudflare Frontend Deployment (optional)

Set the following in GitHub → Settings → Secrets and variables:

- Variables:
  - `ENABLE_FRONTEND_DEPLOYMENT=true`
  - `CLOUDFLARE_R2_BUCKET_NAME=<your-bucket>`
  - `FRONTEND_API_BASE_URL=<your-api>` (optional; defaults to code’s built-in URL)
  - `CLOUDFLARE_ZONE_ID` (optional, for cache purging)
- Secrets:
  - `CLOUDFLARE_API_TOKEN`
  - `CLOUDFLARE_ACCOUNT_ID`

The frontend code defaults to `https://bingus.slimevr.io`. To override, set `FRONTEND_API_BASE_URL`.

## Recommended Models

- <https://tfhub.dev/google/universal-sentence-encoder-large/5>
- <https://tfhub.dev/google/universal-sentence-encoder-multilingual-large/3>

## Compiling ONNX Runtime Extensions

- Link: <https://github.com/microsoft/onnxruntime-extensions>
- Reference: <https://github.com/microsoft/onnxruntime-extensions/blob/main/docs/development.md>

To compile ONNX Runtime Extensions, run the following commands:

```bash
git clone --recurse-submodules https://github.com/microsoft/onnxruntime-extensions.git
cd onnxruntime-extensions
```

### For Windows

```cmd
rem Run the provided build script for Windows
build.bat
```

### For Linux

```bash
# Run the provided build script for Linux
bash ./build.sh
```

The output file will be quite large (100+ MB), so to reduce the size, you can strip all debug information with this command:

```bash
strip --strip-all libortextensions.so
```

## Converting TensorFlow model to ONNX model

- Link: <https://github.com/onnx/tensorflow-onnx>

To convert the TensorFlow model to an ONNX model, you will need to have the ONNX Runtime Extensions, then run the following commands:

```bash
# Install required packages
pip install -U onnx tensorflow tensorflow_text tf2onnx

# Convert the model
python -m tf2onnx.convert --saved-model ./models/tensorflow/use_l_v5/ --output ./models/onnx/use_l_v5.onnx --load_op_libraries libortextensions.so --opset 17 --extra_opset ai.onnx.contrib:1
```
