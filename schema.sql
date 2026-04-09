CREATE TABLE IF NOT EXISTS assets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    purchase_date TEXT,
    notes TEXT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    asset_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    frequency_days INTEGER NOT NULL,
    last_done_date TEXT,
    next_due_date TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (asset_id) REFERENCES assets (id)
);

CREATE TABLE IF NOT EXISTS maintenance_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    completed_at TEXT NOT NULL,
    notes TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks (id)
);
