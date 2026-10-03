# Multi-stage production container for Calculator Application
FROM python:3.12-alpine AS base

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run test suite by default
CMD ["pytest", "-v"]
