#!/bin/zsh
aws ecr get-login-password --region <REGION_PLACEHOLDER> | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com
cd ./nmap-service
docker build --no-cache --platform linux/amd64 -t bounty-hunter/nmap-service .
docker tag bounty-hunter/nmap-service:latest <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/nmap-service:latest
docker push <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/nmap-service:latest
cd ../dnsrecon-service
docker build --no-cache --platform linux/amd64 -t bounty-hunter/dnsrecon-service .
docker tag bounty-hunter/dnsrecon-service:latest <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/dnsrecon-service:latest
docker push <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/dnsrecon-service:latest
cd ../ffuf-service
docker build --no-cache --platform linux/amd64 -t bounty-hunter/ffuf-service .
docker tag bounty-hunter/ffuf-service:latest <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/ffuf-service:latest
docker push <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/ffuf-service:latest
cd ../whois-service
docker build --no-cache --platform linux/amd64 -t bounty-hunter/whois-service .
docker tag bounty-hunter/whois-service:latest <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/whois-service:latest
docker push <AWS_ACCOUNT_ID_PLACEHOLDER>.dkr.ecr.<REGION_PLACEHOLDER>.amazonaws.com/bounty-hunter/whois-service:latest
