from datetime import datetime
from flask import Blueprint, jsonify, request

from app.db import get_db_connection
from app.services.maintenance_service import calculate_next_due_date

tasks_bp = Blueprint("tasks", __name__)


@tasks_bp.get("/tasks")
def get_tasks():
    asset_id = request.args.get("asset_id")

    conn = get_db_connection()

    if asset_id:
        rows = conn.execute(
            """
            SELECT id, asset_id, title, description, frequency_days,
                   last_done_date, next_due_date, created_at
            FROM tasks
            WHERE asset_id = ?
            ORDER BY id ASC
            """,
            (asset_id,),
        ).fetchall()
    else:
        rows = conn.execute(
            """
            SELECT id, asset_id, title, description, frequency_days,
                   last_done_date, next_due_date, created_at
            FROM tasks
            ORDER BY id ASC
            """
        ).fetchall()

    conn.close()

    tasks = [dict(row) for row in rows]
    return jsonify({"tasks": tasks}), 200


@tasks_bp.post("/tasks")
def create_task():
    data = request.get_json(silent=True) or {}

    asset_id = data.get("asset_id")
    title = data.get("title")
    description = data.get("description")
    frequency_days = data.get("frequency_days")
    created_at = datetime.utcnow().isoformat()

    if not asset_id or not title or frequency_days is None:
        return jsonify({
            "error": "Fields 'asset_id', 'title', and 'frequency_days' are required"
        }), 400

    conn = get_db_connection()

    asset = conn.execute(
        """
        SELECT id FROM assets WHERE id = ?
        """,
        (asset_id,),
    ).fetchone()

    if asset is None:
        conn.close()
        return jsonify({"error": "Asset not found"}), 404

    cursor = conn.execute(
        """
        INSERT INTO tasks (
            asset_id, title, description, frequency_days,
            last_done_date, next_due_date, created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (asset_id, title, description, frequency_days, None, None, created_at),
    )
    conn.commit()

    new_id = cursor.lastrowid

    row = conn.execute(
        """
        SELECT id, asset_id, title, description, frequency_days,
               last_done_date, next_due_date, created_at
        FROM tasks
        WHERE id = ?
        """,
        (new_id,),
    ).fetchone()

    conn.close()

    return jsonify(dict(row)), 201


@tasks_bp.post("/tasks/<int:task_id>/complete")
def complete_task(task_id):
    data = request.get_json(silent=True) or {}

    completed_at = data.get("completed_at")
    notes = data.get("notes")

    if not completed_at:
        return jsonify({"error": "Field 'completed_at' is required"}), 400

    try:
        datetime.strptime(completed_at, "%Y-%m-%d")
    except ValueError:
        return jsonify({"error": "Field 'completed_at' must be in YYYY-MM-DD format"}), 400

    conn = get_db_connection()

    task = conn.execute(
        """
        SELECT id, asset_id, title, description, frequency_days,
               last_done_date, next_due_date, created_at
        FROM tasks
        WHERE id = ?
        """,
        (task_id,),
    ).fetchone()

    if task is None:
        conn.close()
        return jsonify({"error": "Task not found"}), 404

    next_due_date = calculate_next_due_date(completed_at, task["frequency_days"])

    conn.execute(
        """
        INSERT INTO maintenance_logs (task_id, completed_at, notes)
        VALUES (?, ?, ?)
        """,
        (task_id, completed_at, notes),
    )

    conn.execute(
        """
        UPDATE tasks
        SET last_done_date = ?, next_due_date = ?
        WHERE id = ?
        """,
        (completed_at, next_due_date, task_id),
    )

    conn.commit()

    updated_task = conn.execute(
        """
        SELECT id, asset_id, title, description, frequency_days,
               last_done_date, next_due_date, created_at
        FROM tasks
        WHERE id = ?
        """,
        (task_id,),
    ).fetchone()

    conn.close()

    return jsonify({
        "message": "Task marked as completed",
        "task": dict(updated_task)
    }), 200
