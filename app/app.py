from flask import Flask, jsonify

from flask_cors import CORS

from app.db import init_db
from app.routes.assets import assets_bp
from app.routes.tasks import tasks_bp
from app.routes.logs import logs_bp

app = Flask(__name__)
CORS(app)

init_db()

app.register_blueprint(assets_bp)
app.register_blueprint(tasks_bp)
app.register_blueprint(logs_bp)

@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
