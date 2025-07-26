import argparse
from google.cloud import storage
import os

def fetch(bucket_name, src, dst):
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(src)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    blob.download_to_filename(dst)
    print(f"Fetched gs://{bucket_name}/{src} → {dst}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("bucket", help="GCS bucket name")
    p.add_argument("src",    help="Object path in bucket")
    p.add_argument("dst",    help="Local destination path")
    args = p.parse_args()
    fetch(args.bucket, args.src, args.dst)
