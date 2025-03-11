from botocore.exceptions import ClientError
import ipaddress
import validators
import time
import subprocess
import boto3
import os
import logging
import json
import sys

QUEUE_URL = os.environ['QUEUE_URL']
BUCKET_NAME = os.environ['BUCKET_NAME']
AWS_REGION = os.environ['AWS_REGION']

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

def main():
    sqs = boto3.client(
    'sqs',  
    region_name=AWS_REGION
    )

    while True:
        try:
            messages = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=5 
            )
        except ClientError as e:
            logging.error("Failed to receive message from queue...")
            time.sleep(5)
            continue
            
        message = messages.get('Messages', [])[0] if messages.get('Messages', []) else None
        content = json.loads(message['Body']) if message else None
        target = content.get('target', None) if content else None

        if not target:
            continue

        logging.info(f"Received target: {target}")
        whois = Whois()

        if not whois.validate_target(target):
            logging.error(f"Invalid target: {target}")
            return
        
        sqs.delete_message(
        QueueUrl=QUEUE_URL,
        ReceiptHandle=message['ReceiptHandle']
        )
        logging.info(f"Deleted message ID: {message}")
            
        whois.start_whois()
        whois.upload_result()



class Whois:
    def validate_target(self, target: str) -> bool:
        try:
            ipaddress.ip_address(target)
            self.TARGET = target
            return True
        except ValueError:
            pass

        if validators.domain(target):
            self.TARGET = target
            return True

        if validators.url(target):
            self.TARGET = target
            return True

        return False

    
    def start_whois(self):
        whois_scan = subprocess.run(
            ['whois', f'{self.TARGET}'], 
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
            )
        self.whois_result = whois_scan.stdout
        logging.info(f"whois scan result: {self.whois_result}")
        
    def upload_result(self):
        s3 = boto3.client(
            's3', 
            region_name=AWS_REGION
        )
        
        try:
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=f'whois/{self.TARGET}.txt',
                Body=self.whois_result
            )
            
            logging.info(f"Uploaded whois result to S3: {self.TARGET}.txt")

        except ClientError as e:
            logging.error(f"Failed to upload whois result to S3: {e}")


if __name__ == "__main__":
    main()