# Messaging-system

# Messaging System with RabbitMQ/Celery and Python Application behind Nginx
**This project implements a messaging system using Flask and Celery for asynchronous email sending. Below is an overview of the project structure and functionality:**

## Requirements
- RabbitMQ
- Python 3.8+
- Nginx
- ngrok (optional, for exposing the local endpoint)


## Project Structure

- **app.py**: Flask application handling HTTP requests.
- **celery_tasks.py**: Celery tasks for asynchronous email sending.
- **celeryconfig.py**: Configuration file for Celery settings.
- **.env**: Environment variables file for SMTP configuration.
- **requirements.txt**: Dependencies


## Setup and Dependencies

Update Package List
```sh
sudo apt-get update
```

Install RabbitMQ:
```sh
sudo apt-get install rabbitmq-server python3 python3-pip
```

Install and upgrade necessary Python packages
```sh
pip3 install --upgrade flask werkzeug celery python-dotenv pytest
```

Ensure you have Python 3 and pip installed. Use the following commands to set up the environment:
```bash
pip install -r requirements.txt
```

Install nginx
```sh
sudo apt-get install -y nginx
```

Configure Nginx to serve the flask Application
modify the nginx config file
```
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Install ngrok
```sh
sudo wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O /tmp/ngrok.zip
sudo unzip -o /tmp/ngrok.zip -d /usr/local/bin/
sudo chmod +x /usr/local/bin/ngrok
```

```sh
sudo systemctl restart nginx
```

Start RabbitMQ server
```sh
sudo systemctl start rabbitmq-server
```

Start Celery worker
```sh
nohup celery -A celery_tasks worker --loglevel=info > celery.log 2>&1 &
```

Start Flask application
```sh
nohup python3 -u -m flask run --host=127.0.0.1 --port=5000 > flask.log 2>&1 &
```

Start ngrok to expose the application
```sh
nohup ngrok http 5000 --config=$HOME/.config/ngrok/ngrok.yml > ngrok.log 2>&1 &
```