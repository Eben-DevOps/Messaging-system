from celery import Celery
from smtplib import SMTP
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize Celery
celery = Celery('tasks')
celery.config_from_object('celeryconfig')

@celery.task
def send_email(recipient):
    """
    Task to send an email using SMTP.
    :param recipient: The email address to send the email to.
    """
    smtp_server = os.getenv('EMAIL_HOST')
    smtp_port = int(os.getenv('EMAIL_PORT'))
    sender_email = os.getenv('EMAIL_USER')
    sender_password = os.getenv('EMAIL_PASSWORD')
    
    with SMTP(smtp_server, smtp_port) as server:
        server.starttls()  # Secure the connection
        server.login(sender_email, sender_password)  # Login to the SMTP server
        message = f"Subject: Test Email\n\nThis is a test email to {recipient}"
        server.sendmail(sender_email, recipient, message)  # Send the email
