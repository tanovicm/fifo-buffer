FROM python:3.11-alpine

RUN apk add --no-cache \
    zeromq-dev \
    gcc \
    musl-dev \
    libffi-dev

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY gen/ ./gen/
COPY client.py .

CMD ["python", "client.py"]