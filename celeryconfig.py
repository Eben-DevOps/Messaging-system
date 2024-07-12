from __future__ import absolute_import, unicode_literals
from celery import Celery

CELERY_BROKER_URL = 'amqp://localhost'
CELERY_RESULT_BACKEND = 'rpc://'

celery = Celery('tasks')
celery.config_from_object('celeryconfig')

# Optional configuration
celery.conf.update(
    task_routes={
        'celery_tasks.*': {'queue': 'celery'},
    }
)

if __name__ == '__main__':
    celery.start()
