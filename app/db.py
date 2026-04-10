import os
import sqlite3
from pathlib import Path

import psycopg

BASE_DIR = Path(__file__).resolve().parent.parent
SCHEMA_PATH = BASE_DIR / "schema.sql"

DB_TYPE = os.getenv("DB_TYPE", "sqlite")

DEFAULT_DB_PATH = BASE_DIR / "database" / "app.db"
DB_PATH = Path(os.getenv("DB_PATH", str(DEFAULT_DB_PATH)))

PG_HOST = os.getenv("PG_HOST", "db")
PG_PORT = os.getenv("PG_PORT", "5432")
PG_DB = os.getenv("PG_DB", "tracker")
PG_USER = os.getenv("PG_USER", "tracker")
PG_PASSWORD = os.getenv("PG_PASSWORD", "tracker")


def get_db_connection():
    if DB_TYPE == "sqlite":
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn

    if DB_TYPE == "postgres":
        return psycopg.connect(
            host=PG_HOST,
            port=PG_PORT,
            dbname=PG_DB,
            user=PG_USER,
            password=PG_PASSWORD,
        )

    raise NotImplementedError(f"Unsupported DB_TYPE: {DB_TYPE}")


def init_db():
    if DB_TYPE == "sqlite":
        DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        conn = get_db_connection()
        with open(SCHEMA_PATH, "r") as f:
            conn.executescript(f.read())
        conn.commit()
        conn.close()
        return

    if DB_TYPE == "postgres":
        conn = get_db_connection()
        with open(SCHEMA_PATH, "r") as f:
            schema_sql = f.read()
        with conn.cursor() as cur:
            cur.execute(schema_sql)
        conn.commit()
        conn.close()
        return

    raise NotImplementedError(f"Unsupported DB_TYPE: {DB_TYPE}")


if __name__ == "__main__":
    init_db()
    print("Database initialized")
