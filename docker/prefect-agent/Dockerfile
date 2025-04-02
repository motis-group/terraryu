FROM prefecthq/prefect:2-python3.10

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy Prefect files
COPY prefect /app/prefect

# Set environment variables
ENV PYTHONPATH=/app

# Set the entrypoint
CMD ["prefect", "agent", "start", "-p", "default-agent-pool"] 