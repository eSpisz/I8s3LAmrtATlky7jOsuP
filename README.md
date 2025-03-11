# BountyHunter

## General Information
It's **only** PoC project. Purpose of this project is to automate pentesters/bug hunters work with automated scanning services hosted in AWS. Technologies used:
- Python
- AWS
- Docker
- Terraform

Project consists of small container services with api in each one. container have scanning applications inside like:
- nmap
- ffuf
- dnsrecon
- whois

Project has modular and repeatable architecture for future development possibility. 

## Architecture diagram

![Architecture](/diagram.drawio.png)

## Usage

1. Build docker images e.g. via build.sh script or manually and push to AWS ECR. When using build.sh change placeholders and fill it with the repo names
2. Create S3 bucket to store scanning results
3. When you have got your AWS ECR and S3 bucket ready - change variables in variables.tf with your values
4. HTTP API Gateway validates requests with IAM auth method so every request must be signed. Example of code how to send the request is called make_request.py
5. Payload must be {target: target_domain} - only domain or ip address without any prefixes or suffixes
6. Scanning results are stored in your bucket created in step 2