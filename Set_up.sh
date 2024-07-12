#!/bin/bash

LOGFILE="setup.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

echo "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y rabbitmq-server python3 python3-pip nginx

echo "Installing necessary Python packages..."
pip3 install --upgrade flask werkzeug celery python-dotenv pytest

# Check if requirements.txt exists
if [ -f requirements.txt ]; then
    echo "Installing additional Python packages from requirements.txt..."
    pip3 install -r requirements.txt
else
    echo "No requirements.txt found. Skipping additional package installation."
fi

echo "Restarting Nginx service..."
sudo systemctl restart nginx

echo "Setup complete."
