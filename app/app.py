from flask import Flask, jsonify
from pathlib import Path
import sqlite3

from app.routes.assets import assets_bp
from app.routes.tasks import tasks_bp
from app.routes.logs import logs_bp


def init_db():
    base_dir = Path(__file__).resolve().parent.parent
    db_dir = base_dir / "database"
    db_path = db_dir / "app.db"
    schema_path = base_dir / "schema.sql"

    db_dir.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(db_path)
    with open(schema_path, "r") as schema_file:
        conn.executescript(schema_file.read())
    conn.commit()
    conn.close()


app = Flask(__name__)

init_db()

app.register_blueprint(assets_bp)
app.register_blueprint(tasks_bp)
app.register_blueprint(logs_bp)


@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
