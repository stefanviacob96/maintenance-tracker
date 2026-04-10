from flask import Blueprint, jsonify

from app.db import get_db_connection

logs_bp = Blueprint("logs", __name__)


@logs_bp.get("/tasks/<int:task_id>/logs")
def get_task_logs(task_id):
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT id
            FROM tasks
            WHERE id = %s
            """,
            (task_id,),
        )
        task = cur.fetchone()

        if task is None:
            conn.close()
            return jsonify({"error": "Task not found"}), 404

        cur.execute(
            """
            SELECT id, task_id, completed_at, notes
            FROM maintenance_logs
            WHERE task_id = %s
            ORDER BY completed_at DESC, id DESC
            """,
            (task_id,),
        )
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
    conn.close()

    logs = [dict(zip(columns, row)) for row in rows]
    return jsonify({"logs": logs}), 200
