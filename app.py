from flask import Flask, request, jsonify
from celery_tasks import send_email
import logging
import time
import os

app = Flask(__name__)

log_file_path = os.path.join(os.getcwd(), 'logs', 'messaging_system.log')
logging.basicConfig(filename=log_file_path, level=logging.INFO)

@app.route('/')
def index() -> str:
    sendmail = request.args.get('sendmail')
    email_body = request.args.get('body', 'This is a default email body.')
    talktome = request.args.get('talktome')
    
    if sendmail:
        send_email.delay(sendmail, email_body)
        print(f"Email to {sendmail} is queued.")
        return f"Email to {sendmail} is queued."
    
    if talktome:
        current_time = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime())
        logging.info(f'Current time logged: {current_time}')
        print(f'Current time {current_time} is logged.')
        return f'Current time {current_time} is logged.'
    
    return 'Please provide a valid parameter.'

@app.route('/logs', methods=['GET'])
def get_logs() -> jsonify:
    with open(log_file_path, 'r') as log_file:
        logs = log_file.readlines()
    return jsonify(logs)

if __name__ == '__main__':
    if not os.path.exists('logs'):
        os.makedirs('logs')
    app.run(debug=True)
