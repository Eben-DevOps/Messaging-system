#!/bin/bash

LOGFILE="setup.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

# Update package list and install dependencies
echo "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y rabbitmq-server python3 python3-pip unzip nginx jq

# Add local bin to PATH
export PATH=$PATH:~/.local/bin

# Install necessary Python packages with specific versions
echo "Installing necessary Python packages..."
pip3 install --upgrade flask==2.0.3 werkzeug==2.0.3 celery python-dotenv pytest

# Check if requirements.txt exists and install additional Python packages
if [ -f requirements.txt ]; then
    echo "Installing additional Python packages from requirements.txt..."
    pip3 install -r requirements.txt
else
    echo "No requirements.txt found. Skipping additional package installation."
fi

# Install nginx
echo "Installing nginx..."
sudo apt-get install -y nginx

# Install ngrok if not already installed or update to the latest version
NGROK_DOWNLOAD_URL="https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip"
NGROK_INSTALL_DIR="/usr/local/bin"

if ! command -v ngrok &> /dev/null; then
    echo "Ngrok not found. Installing..."
    sudo wget -q -O /tmp/ngrok.zip $NGROK_DOWNLOAD_URL
    sudo unzip -o /tmp/ngrok.zip -d $NGROK_INSTALL_DIR
    sudo chmod +x $NGROK_INSTALL_DIR/ngrok
    rm /tmp/ngrok.zip
else
    echo "Ngrok already installed. Updating to the latest version..."
    sudo wget -q -O /tmp/ngrok.zip $NGROK_DOWNLOAD_URL
    sudo unzip -o /tmp/ngrok.zip -d $NGROK_INSTALL_DIR
    sudo chmod +x $NGROK_INSTALL_DIR/ngrok
    rm /tmp/ngrok.zip
fi

# Set up ngrok with authentication token
echo "Setting up ngrok..."

# Read ngrok auth token from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN
else
    echo "Error: .env file not found. Make sure to create one with NGROK_AUTH_TOKEN."
    exit 1
fi

# Determine the home directory dynamically
HOME_DIR=$(eval echo ~$USER)
NGROK_CONFIG_PATH="$HOME_DIR/.config/ngrok/ngrok.yml"

# Add ngrok authentication token to ngrok.yml
mkdir -p "$(dirname "$NGROK_CONFIG_PATH")"
echo "authtoken: $NGROK_AUTH_TOKEN
tunnels:
  flask-app:
    proto: http
    addr: 5000" > "$NGROK_CONFIG_PATH"

# Ensure log directory exists and set permissions
sudo mkdir -p /var/log/messaging_system
sudo touch /var/log/messaging_system/messaging_system.log
sudo chown $USER:$USER /var/log/messaging_system/messaging_system.log

echo "Setup complete."
