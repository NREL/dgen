#!/bin/env python3
import os
import requests
from tqdm import tqdm

def main():
    FILE_DOWNLOAD_INFO_FILE="/data/DB_SQL_FILE_URL.tmp"  # This file contains the url of the file downloading
    DOWNLOAD_FILE="/data/dgen_db.sql"                    # The path to the file being downloaded

    # The file is already fully downloaded
    if not os.path.exists(FILE_DOWNLOAD_INFO_FILE) and os.path.exists(DOWNLOAD_FILE):
        print("dgen is ready to use.")
        exit(0)

    # The file is already fully downloaded
    if not os.path.exists(DOWNLOAD_FILE):
        Fprint("dgen is missing the sql file {DOWNLOAD_FILE}.")
        exit(0)

    try:
        with open(FILE_DOWNLOAD_INFO_FILE, "r") as file:
            FILE_URL = file.readline().strip()  # Read and remove any extra spaces/newlines
    except FileNotFoundError:
        print(f"Error: File {FILE_DOWNLOAD_INFO_FILE} not found.")
        exit(1)

    if not FILE_URL:
        print(f"Error: No URL found in {FILE_DOWNLOAD_INFO_FILE}")
        exit(1)

    # Get file size using HEAD request
    response = requests.head(FILE_URL)
    if 'Content-Length' not in response.headers:
        print("Failed to retrieve file size.")
        exit(1)

    total_size = int(response.headers['Content-Length'])  # Get file size in bytes
    print(f"File size: {total_size} bytes (~{total_size / (1024**3):.2f} GB)")

    # Download file with progress bar
    chunk_size = 1024 * 1024  # 1MB chunks
    downloaded_size = 0

if __name___ == "main":
    main()