from celery import Celery
from smtplib import SMTP
import os
from dotenv import load_dotenv

load_dotenv()

celery = Celery('tasks')
celery.config_from_object('celeryconfig')

@celery.task
def send_email(recipient: str, email_body: str) -> None:
    smtp_server = os.getenv('EMAIL_HOST')
    smtp_port = int(os.getenv('EMAIL_PORT'))
    sender_email = os.getenv('EMAIL_USER')
    sender_password = os.getenv('EMAIL_PASSWORD')
    
    with SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(sender_email, sender_password)
        message = f"Subject: Test Email\n\n{email_body}"
        server.sendmail(sender_email, recipient, message)
