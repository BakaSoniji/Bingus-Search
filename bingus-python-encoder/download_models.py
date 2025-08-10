#!/usr/bin/env python3
"""
Model Download Script for Bingus Encoder

Downloads sentence transformer models during container build to bundle them
into the image for faster, more reliable runtime startup.
"""

import os
import time
from sentence_transformers import SentenceTransformer


def download_models():
    """Download and verify sentence transformer models."""
    
    # Models to pre-download (order: best quality first, with fallbacks)
    models = [
        "all-mpnet-base-v2",                         # 768-dim, high quality
        "sentence-transformers/all-mpnet-base-v2",   # Alternative HF path
        "all-MiniLM-L6-v2"                          # 384-dim, lightweight fallback
    ]
    
    cache_dir = "/bundled-models"
    os.makedirs(cache_dir, exist_ok=True)
    
    print("🏗️  Starting model download during container build...")
    print(f"📂 Cache directory: {cache_dir}")
    
    for i, model_name in enumerate(models, 1):
        try:
            print(f"📦 [{i}/{len(models)}] Downloading {model_name}...")
            start_time = time.time()
            
            # Download with explicit cache folder
            model = SentenceTransformer(model_name, cache_folder=cache_dir)
            
            download_time = time.time() - start_time
            dimensions = model.get_sentence_embedding_dimension()
            
            print(f"✅ Downloaded {model_name} in {download_time:.1f}s")
            print(f"📊 Embedding dimension: {dimensions}")
            
            # Verify the model works
            test_embedding = model.encode("test sentence")
            print(f"✅ Model verified (embedding shape: {test_embedding.shape})")
            
            # Success - stop trying other models
            print(f"🎯 Using {model_name} as primary model")
            break
            
        except Exception as e:
            print(f"❌ Failed to download {model_name}: {e}")
            if i < len(models):
                print("🔄 Trying next model...")
                continue
            else:
                print("⚠️  All model downloads failed - runtime will attempt download")
                print("🔧 This might be due to network connectivity during build")
                return False
    
    print("🏁 Model download completed successfully!")
    return True


if __name__ == "__main__":
    success = download_models()
    exit(0 if success else 1)