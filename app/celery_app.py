import os
from celery import Celery

REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")

celery_app = Celery(
    "maintenance_tracker",
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=["app.tasks"],
)

celery_app.conf.update(
    task_track_started=True,
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    	beat_schedule={
        	"cleanup-old-jobs-daily": {
            	"task": "app.tasks.cleanup_old_jobs",
            	"schedule": 86400.0,
        	},
    	},
)
