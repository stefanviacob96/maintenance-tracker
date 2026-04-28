import logging

from flask import Blueprint, request, jsonify
from celery.result import AsyncResult
from app.celery_app import celery_app
from app.tasks import run_script
from app.services.job_history_service import create_job as save_job

jobs_bp = Blueprint("jobs", __name__)
logger = logging.getLogger("personal-tracker-jobs")


@jobs_bp.route("/jobs", methods=["POST"])
def create_job():
    data = request.get_json()
    script_name = data.get("script")
    logger.info("job_submit_received script=%s", script_name)

    if not script_name:
        logger.warning("job_submit_rejected reason=missing_script")
        return jsonify({"error": "Missing script name"}), 400

    task = run_script.delay(script_name)
    logger.info("job_queued task_id=%s script=%s", task.id, script_name)
    save_job(task.id, script_name)
    logger.info("job_saved task_id=%s script=%s status=PENDING", task.id, script_name)

    return jsonify({
        "message": "Job submitted",
        "task_id": task.id,
        "script": script_name,
        "status_url": f"/jobs/{task.id}"
    }), 202

@jobs_bp.route("/jobs/history", methods=["GET"])
def get_jobs_history():
    logger.info("job_history_requested limit=50")
    from app.db import get_db_connection

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, task_id, script_name, status, result, created_at
                FROM jobs
                ORDER BY created_at DESC
                LIMIT 50
            """)
            rows = cur.fetchall()

        jobs = []
        for row in rows:
            jobs.append({
                "id": row[0],
                "task_id": row[1],
                "script": row[2],
                "status": row[3],
                "result": row[4],
                "created_at": str(row[5]),
            })

        return jsonify(jobs), 200
    finally:
        conn.close()

@jobs_bp.route("/jobs/<task_id>", methods=["GET"])
def get_job(task_id):
    logger.info("job_status_requested task_id=%s", task_id)
    task = AsyncResult(task_id, app=celery_app)

    response = {
        "task_id": task_id,
        "status": task.status,
    }

    if task.successful():
        result = task.result

        stdout = result.get("stdout", "").strip()
        returncode = result.get("returncode", 1)
        script = result.get("script")

        # interpretare simplă
        if returncode == 0 and stdout.startswith("OK"):
            status_text = "OK"
        else:
            status_text = "ERROR"

        # parsare pentru memory_check
        parsed = {}

        if script == "memory_check" and "memory usage" in stdout:
            try:
                parts = stdout.replace("OK: ", "").split()

                usage = parts[3].replace("%", "")
                threshold = parts[4].split("=")[1].replace("%)", "")
                timestamp = stdout.split(" at ")[-1]

                parsed = {
                    "usage_percent": int(usage),
                    "threshold_percent": int(threshold),
                    "timestamp": timestamp
                }
            except Exception:
                parsed = {}

	# parsare pentru disk_check
        if script == "disk_check" and "disk usage" in stdout:
            try:
                parts = stdout.replace("OK: ", "").split()

                usage = parts[4].replace("%", "")
                threshold = parts[6].split("=")[1].replace("%)", "")
                mount = parts[3]
                timestamp = stdout.split(" at ")[-1]

                parsed = {
                    "mount": mount,
                    "usage_percent": int(usage),
                    "threshold_percent": int(threshold),
                    "timestamp": timestamp
                }
            except Exception:
                parsed = {}

        # parsare pentru cpu_check
        if script == "cpu_check" and "cpu usage" in stdout.lower():
            try:
                text = stdout.replace("OK: ", "").replace("ok: ", "")
                parts = text.split()

                # ex: "cpu usage is 12% (threshold=80%) at ..."
                usage = parts[3].replace("%", "")
                threshold = parts[4].split("=")[1].replace("%)", "")
                timestamp = stdout.split(" at ")[-1]

                parsed = {
                    "usage_percent": int(usage),
                    "threshold_percent": int(threshold),
                    "timestamp": timestamp
                }
            except Exception:
                parsed = {}

        response.update({
            "script": script,
            "result": status_text,
            "parsed": parsed,
            "raw_output": stdout
        })

    if task.failed():
        response["result"] = "ERROR"
        response["error"] = str(task.result)

    return jsonify(response), 200

