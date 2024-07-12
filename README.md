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

Ensure you have Python 3 and pip installed. Use the following commands to set up the environment:
```bash
pip install -r requirements.txt
```

Install RabbitMQ:

```sh
sudo apt-get update
sudo apt-get install rabbitmq-server
```
