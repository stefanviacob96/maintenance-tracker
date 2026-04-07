import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "database" / "app.db"
SCHEMA_PATH = BASE_DIR / "schema.sql"


def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db_connection()
    with open(SCHEMA_PATH, "r") as f:
        conn.executescript(f.read())
    conn.close()


if __name__ == "__main__":
    init_db()
    print("Database initialized at:", DB_PATH)

