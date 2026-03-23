# Use Python 3.8 slim (matching original project requirement)
FROM python:3.8.13-slim-bullseye

WORKDIR /usr/src/app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gcc \
    g++ \
    python3-dev \
    libpq-dev \
    postgresql-client \
    libxslt-dev \
    libxml2-dev \
    libffi-dev \
    libssl-dev \
    libjpeg-dev \
    zlib1g-dev \
    libgeos-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip (cap at <24.1 for celery 4.4.2 metadata compat)
RUN pip install --upgrade "pip<24.1" setuptools wheel

# Install Python dependencies
COPY ./requirements/ /tmp/requirements/
RUN pip install -r /tmp/requirements/local.txt && rm -rf /tmp/requirements/

# Copy entrypoint
COPY ./entrypoint.sh .
RUN sed -i 's/\r$//' /usr/src/app/entrypoint.sh && chmod +x /usr/src/app/entrypoint.sh

# Copy project
COPY . .
