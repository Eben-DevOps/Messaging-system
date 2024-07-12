#!/bin/bash

LOGFILE="setup.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

echo "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y rabbitmq-server python3 python3-pip nginx

echo "Installing necessary Python packages..."
pip3 install Flask celery python-dotenv pytest

echo "Creating project directory..."
mkdir -p messaging_system/logs
cd messaging_system

# Check if .env file exists before creating
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat <<EOT >> .env
EMAIL_HOST=smtp.office365.com
EMAIL_PORT=587
EMAIL_USER=your_office365_email@example.com
EMAIL_PASSWORD=your_office365_password
EOT
else
    echo ".env file already exists. Skipping creation."
fi

# Check if requirements.txt exists before creating
if [ ! -f requirements.txt ]; then
    echo "Creating requirements.txt..."
    cat <<EOT >> requirements.txt
Flask==3.0.3
celery==5.4.0
python-dotenv==1.0.1
pytest==8.2.2
EOT
else
    echo "requirements.txt already exists. Skipping creation."
fi

# Check if celeryconfig.py exists before creating
if [ ! -f celeryconfig.py ]; then
    echo "Creating celeryconfig.py..."
    cat <<EOT >> celeryconfig.py
broker_url = 'pyamqp://guest@localhost//'
result_backend = 'rpc://'
EOT
else
    echo "celeryconfig.py already exists. Skipping creation."
fi

# Check if celery_tasks.py exists before creating
if [ ! -f celery_tasks.py ]; then
    echo "Creating celery_tasks.py..."
    cat <<EOT >> celery_tasks.py
from celery import Celery
from smtplib import SMTP
import os
from dotenv import load_dotenv

load_dotenv()

celery = Celery('tasks')
celery.config_from_object('celeryconfig')

@celery.task
def send_email(recipient: str) -> None:
    smtp_server = os.getenv('EMAIL_HOST')
    smtp_port = int(os.getenv('EMAIL_PORT'))
    sender_email = os.getenv('EMAIL_USER')
    sender_password = os.getenv('EMAIL_PASSWORD')
    
    with SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(sender_email, sender_password)
        message = f"Subject: Test Email\n\nThis is a test email to {recipient}"
        server.sendmail(sender_email, recipient, message)
EOT
else
    echo "celery_tasks.py already exists. Skipping creation."
fi

echo "Creating Nginx configuration file..."
cat <<EOT | sudo tee /etc/nginx/sites-available/default >/dev/null
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT

echo "Symlinking Nginx configuration..."
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

echo "Restarting Nginx service..."
sudo systemctl restart nginx

echo "Starting RabbitMQ server..."
sudo systemctl start rabbitmq-server

echo "Stopping any existing Celery workers..."
pkill -f 'celery -A celery_tasks worker'

echo "Starting Celery worker..."
nohup celery -A celery_tasks worker --loglevel=info &

echo "Starting Flask application..."
nohup python3 -u -m flask run --host=127.0.0.1 --port=5000 > flask.log 2>&1 &

# Start ngrok to expose port 5000 via HTTP
echo "Starting ngrok to expose port 5000..."
nohup /usr/local/bin/ngrok http 5000 > ngrok.log 2>&1 &

echo "Setup complete. You can now access the application."
echo "Use the following commands to test the endpoints:"
echo "Send an email: curl http://localhost:5000/?sendmail=recipient@example.com"
echo "Log current time: curl http://localhost:5000/?talktome=1"
echo "Retrieve logs: curl http://localhost:5000/logs"
