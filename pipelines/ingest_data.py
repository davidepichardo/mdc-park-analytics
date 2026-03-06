#!/usr/bin/env python
# coding: utf-8

import os

import boto3
from dotenv import load_dotenv
from datetime import datetime

load_dotenv() 

bucket_name = os.environ.get("BUCKET_NAME")

def upload_file_to_s3(filename, bucket_name, s3_key):
    s3 = boto3.client('s3')
    try:
        s3.upload_file(filename, bucket_name, s3_key)
        print(f"File '{filename}' uploaded successfully to S3 bucket '{bucket_name}' with key '{s3_key}'.")
    except Exception as e:
        print(f"Error uploading file: {e}")

filename = '../Park_Facility.csv'
s3_key = f"raw/ingested_date={datetime.today().strftime('%Y-%m-%d')}/{filename}"

if __name__ == "__main__":
    upload_file_to_s3(filename, bucket_name, s3_key)


