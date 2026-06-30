#!/usr/bin/env python3
"""
JFrog AI Catalog Workshop — Download a tiny AI model through Artifactory.

Usage:
    python3 download_model.py <NICKNAME>

Environment variables (loaded from ~/.workshop-profile):
    JFROG_URL    - Your JFrog instance URL
    JFROG_TOKEN  - Your Access Token
"""
import os
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 download_model.py <NICKNAME>")
        sys.exit(1)

    nickname = sys.argv[1]
    jfrog_url = os.environ.get("JFROG_URL", "").rstrip("/")
    jfrog_token = os.environ.get("JFROG_TOKEN", "")

    if not jfrog_url or not jfrog_token:
        print("❌ JFROG_URL and JFROG_TOKEN must be set.")
        print("   Run: source ~/.workshop-profile")
        sys.exit(1)

    try:
        from huggingface_hub import HfApi
    except ImportError:
        print("❌ huggingface_hub not installed. Run: pip install huggingface_hub")
        sys.exit(1)

    # Use Artifactory as the Hugging Face endpoint
    hf_endpoint = f"{jfrog_url}/artifactory/api/huggingface/{nickname}-hf-virtual"
    os.environ["HF_ENDPOINT"] = hf_endpoint
    os.environ["HF_TOKEN"] = jfrog_token

    print(f"📡 HuggingFace endpoint: {hf_endpoint}")
    print(f"📦 Downloading tiny test model: hf-internal-testing/tiny-random-BertModel")

    from huggingface_hub import snapshot_download
    local_dir = snapshot_download(
        repo_id="hf-internal-testing/tiny-random-BertModel",
        endpoint=hf_endpoint,
        token=jfrog_token,
        local_dir="./model_download",
        ignore_patterns=["*.h5", "*.ot", "*.msgpack"]
    )

    print(f"✅ Model downloaded to: {local_dir}")
    print("   Check Artifactory: your {}-hf-remote repo should now have cached model files.".format(nickname))

if __name__ == "__main__":
    main()
