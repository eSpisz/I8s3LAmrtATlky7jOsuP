import json
import requests
import datetime
from botocore.session import Session
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest

# Example of how to make a request to the API Gateway endpoint
# =============================================================================
AWS_REGION = "<REGION_PLACEHOLDER>"
SERVICE = "execute-api"
ENDPOINT = "https://<API_ID_PLACEHOLDER>.execute-api.<REGION_PLACEHOLDER>.amazonaws.com/prod/scan"
HOST = "api-id.execute-api.<REGION_PLACEHOLDER>.amazonaws.com"
# =============================================================================
# Example target
payload = json.dumps({"target": "scanme.nmap.org"}).encode("utf-8")
# =============================================================================

session = Session()
credentials = session.get_credentials()

if not credentials:
    raise ValueError("Incorrect Credentials!")

credentials = credentials.get_frozen_credentials()



aws_request = AWSRequest(
    method="POST",
    url=ENDPOINT,
    data=payload,
    headers={
        "Content-Type": "application/json",
        "Host": HOST,
        "x-amz-date": datetime.datetime.now(datetime.UTC),
    }
)

SigV4Auth(credentials, SERVICE, AWS_REGION).add_auth(aws_request)

signed_request = requests.Request(
    method=aws_request.method,
    url=aws_request.url,
    headers=dict(aws_request.headers),
    data=aws_request.body
)

prepared_request = signed_request.prepare()

with requests.Session() as session:
    response = session.send(prepared_request)

print("Status Code:", response.status_code)
print("Response:", response.text)