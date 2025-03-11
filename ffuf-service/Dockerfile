FROM python:alpine

WORKDIR /app

COPY requirements.txt ./requirements.txt

COPY app.py ./app.py

COPY wordlists ./wordlists

RUN apk update && apk add --no-cache ffuf

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "app.py"]