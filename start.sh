#!/bin/bash

LOGFILE="start.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

echo "Stopping any previous instances of the application, Celery workers, and ngrok..."
pkill -f 'flask run'
pkill -f 'celery -A celery_tasks worker'
pkill -f 'ngrok'

echo "Starting RabbitMQ server..."
sudo systemctl start rabbitmq-server
if systemctl is-active --quiet rabbitmq-server; then
    echo "RabbitMQ server started successfully."
else
    echo "Failed to start RabbitMQ server. Check logs for details."
    exit 1
fi

echo "Starting Celery worker..."
nohup celery -A celery_tasks worker --loglevel=info > celery.log 2>&1 &
if ps -p $! > /dev/null; then
    echo "Celery worker started successfully."
else
    echo "Failed to start Celery worker. Check celery.log for details."
    exit 1
fi

echo "Starting Flask application..."
nohup python3 -u -m flask run --host=127.0.0.1 --port=5000 > flask.log 2>&1 &
if ps -p $! > /dev/null; then
    echo "Flask application started successfully."
else
    echo "Failed to start Flask application. Check flask.log for details."
    exit 1
fi

echo "Starting ngrok to expose the application..."
nohup ngrok http 5000 --config=$HOME/.config/ngrok/ngrok.yml > ngrok.log 2>&1 &
sleep 5

NGROK_TUNNELS_URL=$(curl --silent http://localhost:4040/api/tunnels)
PUBLIC_URL=$(echo $NGROK_TUNNELS_URL | jq -r '.tunnels[0].public_url')

if [ -z "$PUBLIC_URL" ]; then
    echo "Failed to fetch ngrok public URL. Check ngrok logs."
else
    echo "Setup complete. You can now access the application via ngrok URL: $PUBLIC_URL"
fi
