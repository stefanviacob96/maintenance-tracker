from datetime import datetime
from flask import Blueprint, jsonify, request

from app.db import get_db_connection

assets_bp = Blueprint("assets", __name__)


@assets_bp.get("/assets")
def get_assets():
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT id, name, category, purchase_date, notes, created_at
            FROM assets
            ORDER BY id ASC
            """
        )
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
    conn.close()

    assets = [dict(zip(columns, row)) for row in rows]
    return jsonify({"assets": assets}), 200


@assets_bp.get("/assets/<int:asset_id>")
def get_asset(asset_id):
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT id, name, category, purchase_date, notes, created_at
            FROM assets
            WHERE id = %s
            """,
            (asset_id,),
        )
        row = cur.fetchone()
        columns = [desc[0] for desc in cur.description] if cur.description else []
    conn.close()

    if row is None:
        return jsonify({"error": "Asset not found"}), 404

    return jsonify(dict(zip(columns, row))), 200


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
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO assets (name, category, purchase_date, notes, created_at)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id, name, category, purchase_date, notes, created_at
            """,
            (name, category, purchase_date, notes, created_at),
        )
        row = cur.fetchone()
        columns = [desc[0] for desc in cur.description]
    conn.commit()
    conn.close()

    return jsonify(dict(zip(columns, row))), 201
