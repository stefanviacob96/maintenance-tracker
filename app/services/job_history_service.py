from app.db import get_db_connection


def create_job(task_id, script_name):
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO jobs (task_id, script_name, status)
                VALUES (%s, %s, %s)
                ON CONFLICT (task_id) DO NOTHING
                """,
                (task_id, script_name, "PENDING"),
            )
        conn.commit()
    finally:
        conn.close()


def update_job(task_id, status, result=None, parsed=None, raw_output=None, error=None):
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE jobs
                SET status = %s,
                    result = %s,
                    parsed = %s,
                    raw_output = %s,
                    error = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE task_id = %s
                """,
                (status, result, parsed, raw_output, error, task_id),
            )
        conn.commit()
    finally:
        conn.close()
