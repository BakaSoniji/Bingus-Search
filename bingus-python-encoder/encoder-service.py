import json
from sentence_transformers import SentenceTransformer
from fastapi import FastAPI
from pydantic import BaseModel


class EncodeRequest(BaseModel):
    sentence: str


import os

with open("./config/encoder_config.json") as f:
    config = json.load(f)

model_file = config["model"]
print(f"Loading model \"{model_file}\"...")

# Check for bundled models first, fallback to cache folder  
bundled_models_dir = "/usr/src/app/bundled-models"

# Try multiple potential paths for the bundled model
potential_paths = [
    f"{bundled_models_dir}/models--sentence-transformers--{model_file}",
    f"{bundled_models_dir}/{model_file}",
    f"{bundled_models_dir}/sentence-transformers--{model_file}"
]

bundled_path = None
for path in potential_paths:
    if os.path.exists(path):
        bundled_path = path
        break

if bundled_path:
    print(f"✅ Using bundled model from: {bundled_path}")
    model = SentenceTransformer(bundled_path)
else:
    print(f"📦 Bundled model not found in {bundled_models_dir}, trying with cache folder...")
    # List what's actually in the bundled models directory for debugging
    if os.path.exists(bundled_models_dir):
        print(f"🔍 Available in {bundled_models_dir}: {os.listdir(bundled_models_dir)}")
    
    # Use the bundled-models directory as cache to avoid re-downloading
    model = SentenceTransformer(model_file, cache_folder=bundled_models_dir)
dimensions = model.get_sentence_embedding_dimension()
print(f"Model \"{model_file}\" loaded with dimension {dimensions}.")
app = FastAPI()


@app.get("/dimensions/")
async def get_dimensions():
    return {"dimensions": dimensions}


@app.post("/encode/")
async def encode_sentence(encode_request: EncodeRequest):
    return {"embedding": [val.item() for val in model.encode(encode_request.sentence)]}
