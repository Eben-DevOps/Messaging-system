#!/bin/bash

LOGFILE="setup.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

# Update package list and install dependencies
sudo apt-get update
sudo apt-get install -y rabbitmq-server python3 python3-pip

# Install necessary Python packages
pip3 install --upgrade flask werkzeug celery python-dotenv pytest

# Check if requirements.txt exists and install additional Python packages
if [ -f requirements.txt ]; then
    echo "Installing additional Python packages from requirements.txt..."
    pip3 install -r requirements.txt
else
    echo "No requirements.txt found. Skipping additional package installation."
fi

# Install nginx
sudo apt-get install -y nginx

# Restart Nginx service
sudo systemctl restart nginx

# Set up ngrok with authentication token
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN
else
    echo "Error: .env file not found. Make sure to create one with NGROK_AUTH_TOKEN."
    exit 1
fi

# Adjust ngrok config path based on home directory
HOME_DIR=$(eval echo "~$(whoami)")
NGROK_CONFIG_PATH="$HOME_DIR/.config/ngrok/ngrok.yml"

# Create ngrok config directory if it doesn't exist
mkdir -p $(dirname $NGROK_CONFIG_PATH)

# Write ngrok configuration to ngrok.yml
echo "authtoken: $NGROK_AUTH_TOKEN" > $NGROK_CONFIG_PATH
echo "tunnels:" >> $NGROK_CONFIG_PATH
echo "  flask-app:" >> $NGROK_CONFIG_PATH
echo "    proto: http" >> $NGROK_CONFIG_PATH  # Protocol used by your application
echo "    addr: 5000" >> $NGROK_CONFIG_PATH   # Port on which your application runs
echo "version: 2" >> $NGROK_CONFIG_PATH       # Ngrok configuration version

echo "Setup complete."
