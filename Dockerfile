FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies (for psycopg2 etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Expose Django default port
EXPOSE 8000

# Run development server (do not use in production)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
