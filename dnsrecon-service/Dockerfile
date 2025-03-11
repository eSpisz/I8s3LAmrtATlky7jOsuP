FROM python:alpine

WORKDIR /app

COPY requirements.txt ./requirements.txt

COPY app.py ./app.py

RUN apk update && apk add --no-cache dnsrecon

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "app.py"]