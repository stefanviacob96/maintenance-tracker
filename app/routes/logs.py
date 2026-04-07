from flask import Blueprint, jsonify

from app.db import get_db_connection

logs_bp = Blueprint("logs", __name__)

@logs_bp.get("/tasks/<int:task_id>/logs")
def get_task_logs(task_id):
    conn = get_db_connection()

    task = conn.execute(
        """
        SELECT id FROM tasks
        WHERE id = ?
        """,
        (task_id,),
    ).fetchone()

    if task is None:
        conn.close()
        return jsonify({"error": "Task not found"}), 404

    rows = conn.execute(
        """
        SELECT id, task_id, completed_at, notes
        FROM maintenance_logs
        WHERE task_id = ?
        ORDER BY completed_at DESC, id DESC
        """,
        (task_id,),
    ).fetchall()

    conn.close()

    logs = [dict(row) for row in rows]
    return jsonify({"logs": logs}), 200
