#!/bin/bash

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

echo "Stopping RabbitMQ server..."
sudo systemctl stop rabbitmq-server

echo "All services stopped."
