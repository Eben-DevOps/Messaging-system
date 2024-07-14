from flask import Flask, request, jsonify
from celery_tasks import send_email
import logging
import time
import os

app = Flask(__name__)

# Ensure /var/log directory exists
log_dir = '/var/log'
if not os.path.exists(log_dir):
    os.makedirs(log_dir, exist_ok=True)

# Set log file path
log_file_path = os.path.join(log_dir, 'messaging_system.log')

# Configure logging with a more readable format
log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
logging.basicConfig(
    filename=log_file_path,
    level=logging.INFO,
    format=log_format,
    datefmt='%Y-%m-%d %H:%M:%S'
)

# Create a logger object
logger = logging.getLogger(__name__)

@app.route('/')
def index() -> str:
    sendmail = request.args.get('sendmail')
    email_body = request.args.get('body', 'This is a default email body.')
    talktome = request.args.get('talktome')
    
    if sendmail:
        send_email.delay(sendmail, email_body)
        logger.info(f"Email to {sendmail} is queued with body: {email_body}")
        return f"Email to {sendmail} is queued."
    
    if talktome is not None:  # Check if talktome parameter is present
        current_time = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime())
        logger.info(f'Current time logged: {current_time}')
        return f'Current time {current_time} is logged.'
    
    return 'Please provide a valid parameter.'

@app.route('/logs', methods=['GET'])
def get_logs():
    try:
        with open(log_file_path, 'r') as log_file:
            logs = log_file.readlines()
        
        # Create an HTML response with the logs
        html_response = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Logs</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    margin: 20px;
                }
                .log-container {
                    background-color: #f4f4f4;
                    padding: 10px;
                    border-radius: 5px;
                    border: 1px solid #ddd;
                }
                .log-entry {
                    margin-bottom: 10px;
                    padding: 8px;
                    border-radius: 5px;
                    border: 1px solid #ccc;
                }
                .log-time {
                    font-weight: bold;
                    color: #666;
                }
                .log-message {
                    margin-left: 10px;
                }
            </style>
        </head>
        <body>
            <h1>Application Logs</h1>
            <div class="log-container">
        """
        
        # Add logs to the HTML response
        for line in logs:
            if line.strip():  # Skip empty lines
                log_time = line.split(' - ')[0]
                log_message = ' - '.join(line.split(' - ')[1:])  # To handle multiline logs
                html_response += f'<div class="log-entry"><span class="log-time">{log_time}</span><span class="log-message">{log_message}</span></div>'
        
        # Close the HTML tags
        html_response += """
            </div>
        </body>
        </html>
        """
        
        return html_response
    
    except FileNotFoundError:
        return jsonify({'error': 'Log file not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
