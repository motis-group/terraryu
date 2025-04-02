FROM prefecthq/prefect:2-python3.10

# Install system dependencies for pandas, numpy, and other data packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy Prefect flows and tasks
COPY prefect /app/prefect

# Set environment variables
ENV PYTHONPATH=/app

# The container will be started by Prefect with the appropriate flow entry point 