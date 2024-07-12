#!/bin/bash

LOGFILE="setup.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

echo "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y rabbitmq-server python3 python3-pip python3-venv nginx

echo "Creating a virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo "Installing necessary Python packages..."
pip install Flask celery python-dotenv pytest

echo "Creating project directory..."
mkdir -p messaging_system/logs
cd messaging_system

echo "Creating .env file..."
cat <<EOT >> .env
EMAIL_HOST=smtp.office365.com
EMAIL_PORT=587
EMAIL_USER=your_office365_email@example.com
EMAIL_PASSWORD=your_office365_password
EOT

echo "Creating requirements.txt..."
cat <<EOT >> requirements.txt
Flask==2.0.3
celery==5.2.3
python-dotenv==0.19.2
pytest==6.2.4
EOT

echo "Creating celeryconfig.py..."
cat <<EOT >> celeryconfig.py
broker_url = 'pyamqp://guest@localhost//'
result_backend = 'rpc://'
EOT

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

echo "Creating app.py..."
cat <<EOT >> app.py
from flask import Flask, request, jsonify
from celery_tasks import send_email
import logging
import time
import os

app = Flask(__name__)

log_file_path = os.path.join(os.getcwd(), 'logs', 'messaging_system.log')
logging.basicConfig(filename=log_file_path, level=logging.INFO)

@app.route('/')
def index() -> str:
    sendmail = request.args.get('sendmail')
    talktome = request.args.get('talktome')
    
    if sendmail:
        send_email.delay(sendmail)
        return f"Email to {sendmail} is queued."
    
    if talktome:
        current_time = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime())
        logging.info(f'Current time logged: {current_time}')
        return f'Current time {current_time} is logged.'
    
    return 'Please provide a valid parameter.'

@app.route('/logs', methods=['GET'])
def get_logs() -> jsonify:
    with open(log_file_path, 'r') as log_file:
        logs = log_file.readlines()
    return jsonify(logs)

if __name__ == '__main__':
    if not os.path.exists('logs'):
        os.makedirs('logs')
    app.run(debug=True)
EOT

echo "Creating Nginx configuration file..."
sudo bash -c 'cat <<EOT > /etc/nginx/sites-available/default
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
EOT'

echo "Restarting Nginx service..."
sudo systemctl restart nginx

echo "Starting RabbitMQ server..."
sudo systemctl start rabbitmq-server

echo "Starting Celery worker..."
nohup ./venv/bin/celery -A celery_tasks worker --loglevel=info &

echo "Starting Flask application..."
nohup ./venv/bin/python app.py &

echo "Setup complete. You can now access the application."
echo "Use the following commands to test the endpoints:"
echo "Send an email: curl http://localhost:5000/?sendmail=recipient@example.com"
echo "Log current time: curl http://localhost:5000/?talktome=1"
echo "Retrieve logs: curl http://localhost:5000/logs"
