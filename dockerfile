# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone Open WebUI repository
RUN git clone https://github.com/open-webui/open-webui.git .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port the app runs on
EXPOSE 8080

# Define environment variable
ENV HOST=0.0.0.0

# Run the application
CMD ["python", "app.py"]