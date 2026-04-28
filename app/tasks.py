import logging
import subprocess
from app.celery_app import celery_app
from app.services.job_history_service import update_job

logger = logging.getLogger("personal-tracker-worker")

ALLOWED_SCRIPTS = {
    "memory_check": "scripts/system/memory-alert-check.sh",
    "disk_check": "scripts/system/disk-alert-check.sh",
    "cpu_check": "scripts/system/cpu-alert-check.sh",
}


@celery_app.task(bind=True)
def run_script(self, script_name):
    task_id = self.request.id
    logger.info("worker_script_requested task_id=%s script=%s", task_id, script_name)
    script_path = ALLOWED_SCRIPTS.get(script_name)

    if script_path is None:
        logger.warning("worker_script_rejected task_id=%s script=%s reason=not_allowed", task_id, script_name)
        return {
            "status": "error",
            "message": f"Script '{script_name}' is not allowed",
        }

    logger.info("worker_script_started task_id=%s script=%s path=%s", task_id, script_name, script_path)

    result = subprocess.run(
        ["bash", script_path],
        capture_output=True,
        text=True
    )
    logger.info("worker_script_finished task_id=%s script=%s returncode=%s", task_id, script_name, result.returncode)

    if result.returncode == 0:
    	status = "SUCCESS"
    	JOB_SUCCESS_COUNT.labels(script_name=script_name).inc()
    else:
    	status = "FAILURE"
    	JOB_FAILURE_COUNT.labels(script_name=script_name).inc()

    logger.info("worker_db_update_started task_id=%s status=%s", task_id, status)

    update_job(
    	task_id=task_id,
    	status=status,
    	result="OK" if status == "SUCCESS" else "ERROR",
    	raw_output=result.stdout,
    	error=result.stderr if status == "FAILURE" else None
    )

    logger.info("worker_db_updated task_id=%s status=%s", task_id, status)

    return {
        "script": script_name,
        "path": script_path,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "returncode": result.returncode,
    }

@celery_app.task
def cleanup_old_jobs():
    logger.info("worker_cleanup_started")
    from app.db import get_db_connection

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                DELETE FROM jobs
                WHERE created_at < NOW() - INTERVAL '7 days'
            """)
        conn.commit()
        logger.info("worker_cleanup_finished")
    finally:
        conn.close()

    return "Old jobs cleaned"
