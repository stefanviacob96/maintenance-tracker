import logging
import time

from flask import Flask, jsonify, request
from flask_cors import CORS
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

from app.db import init_db
from app.routes.assets import assets_bp
from app.routes.tasks import tasks_bp
from app.routes.logs import logs_bp
from app.routes.jobs import jobs_bp


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s"
)

logger = logging.getLogger("maintenance-tracker-api")

from app.metrics import REQUEST_COUNT, REQUEST_LATENCY

from app.metrics import JOB_STATUS_COUNT
from app.db import get_db_connection


app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

init_db()

app.register_blueprint(assets_bp)
app.register_blueprint(tasks_bp)
app.register_blueprint(logs_bp)
app.register_blueprint(jobs_bp)


@app.before_request
def log_request_start():
    if request.path == "/health":
        return

    request.start_time = time.time()
    logger.info("request_started method=%s path=%s", request.method, request.path)


@app.after_request
def log_request_end(response):
    if request.path == "/health":
        return response

    start_time = getattr(request, "start_time", None)
    duration_ms = None

    if start_time is not None:
        duration_seconds = time.time() - start_time
        duration_ms = round(duration_seconds * 1000, 2)
        REQUEST_LATENCY.labels(endpoint=request.path).observe(duration_seconds)

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        http_status=response.status_code
    ).inc()

    logger.info(
        "request_finished method=%s path=%s status=%s duration_ms=%s",
        request.method,
        request.path,
        response.status_code,
        duration_ms
    )

    return response


@app.get("/metrics")
def metrics():
    
    # update job metrics from DB
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT script_name, status, COUNT(*)
                FROM jobs
                GROUP BY script_name, status
            """)
            rows = cur.fetchall()

            # reset before setting
            JOB_STATUS_COUNT.clear()

            for script_name, status, count in rows:
                JOB_STATUS_COUNT.labels(
                    script_name=script_name,
                    status=status
                ).set(count)
    finally:
        conn.close()

    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
