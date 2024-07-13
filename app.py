from flask import Flask, request, jsonify
from celery_tasks import send_email
import logging
import time
import os

app = Flask(__name__)

# Ensure /var/log directory exists
log_dir = '/var/log'
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# Set log file path
log_file_path = os.path.join(log_dir, 'messaging_system.log')

# Configure logging with format
logging.basicConfig(filename=log_file_path, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

@app.route('/')
def index() -> str:
    sendmail = request.args.get('sendmail')
    email_body = request.args.get('body', 'This is a default email body.')
    talktome = request.args.get('talktome')
    
    if sendmail:
        send_email.delay(sendmail, email_body)
        logging.info(f"Email to {sendmail} is queued.")
        return f"Email to {sendmail} is queued."
    
    if talktome is not None:  # Check if talktome parameter is present
        current_time = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime())
        logging.info(f'Current time logged: {current_time}')
        return f'Current time {current_time} is logged.'
    
    return 'Please provide a valid parameter.'

@app.route('/logs', methods=['GET'])
def get_logs() -> jsonify:
    try:
        with open(log_file_path, 'r') as log_file:
            logs = log_file.readlines()
        return jsonify(logs)
    except FileNotFoundError:
        return jsonify({'error': 'Log file not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
