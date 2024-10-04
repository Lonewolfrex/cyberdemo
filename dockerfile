# Use the official Python image from the Docker Hub
FROM python:3.12-alpine

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file to the working directory
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire project directory to the working directory
COPY . .

# Expose the port on which the app will run
EXPOSE 8084

# Run the Django development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
