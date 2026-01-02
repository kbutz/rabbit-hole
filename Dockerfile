# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /app

# Prevent Python from writing pyc files to disc
ENV PYTHONDONTWRITEBYTECODE 1
# Prevent Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED 1

# Install system dependencies (if any needed for python packages)
# RUN apt-get update && apt-get install -y --no-install-recommends gcc python3-dev \
#    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Create a non-root user
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --gid 1001 appuser

# Copy installed dependencies from builder stage
COPY --from=builder /install /usr/local

# Copy application code
COPY main.py index.html ./

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
