from datetime import datetime
from flask import Blueprint, jsonify, request

from app.db import get_db_connection

assets_bp = Blueprint("assets", __name__)


@assets_bp.get("/assets")
def get_assets():
    conn = get_db_connection()
    rows = conn.execute(
        """
        SELECT id, name, category, purchase_date, notes, created_at
        FROM assets
        ORDER BY id ASC
        """
    ).fetchall()
    conn.close()

    assets = [dict(row) for row in rows]
    return jsonify({"assets": assets}), 200


@assets_bp.get("/assets/<int:asset_id>")
def get_asset(asset_id):
    conn = get_db_connection()
    row = conn.execute(
        """
        SELECT id, name, category, purchase_date, notes, created_at
        FROM assets
        WHERE id = ?
        """,
        (asset_id,),
    ).fetchone()
    conn.close()

    if row is None:
        return jsonify({"error": "Asset not found"}), 404

    return jsonify(dict(row)), 200


@assets_bp.post("/assets")
def create_asset():
    data = request.get_json(silent=True) or {}

    name = data.get("name")
    category = data.get("category")
    purchase_date = data.get("purchase_date")
    notes = data.get("notes")
    created_at = datetime.utcnow().isoformat()

    if not name or not category:
        return jsonify({"error": "Fields 'name' and 'category' are required"}), 400

    conn = get_db_connection()
    cursor = conn.execute(
        """
        INSERT INTO assets (name, category, purchase_date, notes, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (name, category, purchase_date, notes, created_at),
    )
    conn.commit()

    new_id = cursor.lastrowid

    row = conn.execute(
        """
        SELECT id, name, category, purchase_date, notes, created_at
        FROM assets
        WHERE id = ?
        """,
        (new_id,),
    ).fetchone()
    conn.close()

    return jsonify(dict(row)), 201
