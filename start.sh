#!/bin/bash

LOGFILE="start.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

echo "Stopping any previous instances of the application, Celery workers, and ngrok..."
pkill -f 'flask run'
pkill -f 'celery -A celery_tasks worker'

# Stop ngrok if running
NGROK_PID=$(pgrep -f 'ngrok start --all --config=/home/eben/.config/ngrok/ngrok.yml')
if [ -n "$NGROK_PID" ]; then
    kill $NGROK_PID
    echo "Stopped ngrok with PID $NGROK_PID"
else
    echo "ngrok is not running"
fi

echo "Starting RabbitMQ server..."
sudo systemctl start rabbitmq-server

echo "Starting Celery worker..."
nohup celery -A celery_tasks worker --loglevel=info > celery.log 2>&1 &

echo "Starting Flask application..."
nohup python3 -u -m flask run --host=127.0.0.1 --port=5000 > flask.log 2>&1 &

echo "Starting ngrok to expose the application..."
nohup ngrok start --all --config=/home/eben/.config/ngrok/ngrok.yml > ngrok.log 2>&1 &

# Wait for ngrok to start (adjust the sleep time based on your ngrok startup time)
sleep 5

# Fetch the public URL from the ngrok API
NGROK_TUNNELS_URL=$(curl --silent http://localhost:4040/api/tunnels)
PUBLIC_URL=$(echo $NGROK_TUNNELS_URL | jq -r '.tunnels[0].public_url')

echo "Setup complete. You can now access the application via ngrok URL: $PUBLIC_URL"
