# Use official Python image
FROM python:3.14.7-slim-trixie

# Set working directory
WORKDIR /app

# Copy code and install dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

# Expose the port Flask runs on
EXPOSE 8080

# Run the app
CMD ["python", "app.py"]