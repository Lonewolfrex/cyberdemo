# Use the official Python image from the Docker Hub
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file to the working directory
COPY requirements.txt .

# Install the Python dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cat requirements.txt 
RUN pip install --no-cache-dir -r requirements.txt  
# Copy the entire project directory to the working directory
COPY . .

# Expose the port on which the app will run
EXPOSE 8084

# Run the Django development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
