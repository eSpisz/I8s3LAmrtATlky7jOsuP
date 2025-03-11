import boto3
import botocore
import os
import json

class Nmap:
    def __init__(self, target):
        self.QUEUE_URL_NMAP = os.environ['QUEUE_URL_NMAP']
        self.target = target

    def prepare_payload(self):
        self.payload = {"target": self.target}
    
    def send_payload(self, sqs):
        response = sqs.send_message(
            QueueUrl=self.QUEUE_URL_NMAP,
            MessageBody=json.dumps(self.payload)
        )
        return response

class Dnsrecon:
    def __init__(self, target):
        self.QUEUE_URL_DNSRECON = os.environ['QUEUE_URL_DNSRECON']
        self.target = target
    
    def prepare_payload(self):
        self.payload = {"target": self.target}

    def send_payload(self, sqs):
        response = sqs.send_message(
            QueueUrl=self.QUEUE_URL_DNSRECON,
            MessageBody=json.dumps(self.payload)
        )
        return response

class Ffuf:
    def __init__(self, target):
        self.QUEUE_URL_FFUF = os.environ['QUEUE_URL_FFUF']
        self.target = target

    def prepare_payload(self):
        self.payload = {"target": f"http://{self.target}/"}

    def send_payload(self, sqs):
        response = sqs.send_message(
            QueueUrl=self.QUEUE_URL_FFUF,
            MessageBody=json.dumps(self.payload)
        )
        return response

class Whois:
    def __init__(self, target):
        self.QUEUE_URL_WHOIS = os.environ['QUEUE_URL_WHOIS']
        self.target = target
    
    def prepare_payload(self):
        self.payload = {"target": self.target}

    def send_payload(self, sqs):
        response = sqs.send_message(
            QueueUrl=self.QUEUE_URL_WHOIS,
            MessageBody=json.dumps(self.payload)
        )
        return response

def lambda_handler(event, context):
    
    sqs = boto3.client('sqs')

    message_body = event.get('body', None)

    if message_body:
        message_to_dict = json.loads(message_body)
        target = message_to_dict.get('target', None)
        if target:
            nmap = Nmap(target)
            dnsrecon = Dnsrecon(target)
            ffuf = Ffuf(target)
            whois = Whois(target)

            nmap.prepare_payload()
            dnsrecon.prepare_payload()
            ffuf.prepare_payload()
            whois.prepare_payload()
        
            try:
                nmap.send_payload(sqs)
                dnsrecon.send_payload(sqs)
                ffuf.send_payload(sqs)
                whois.send_payload(sqs)

            except botocore.exceptions.ClientError as e:
                return {
                    'statusCode': 500,
                    'body': json.dumps({
                        "Status": "Failed to start scan",
                        "Error": str(e)
                    })
                }
    
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            "Status": "Scan has been started",
        })
    }
