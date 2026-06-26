"""
Dummy B — API mínima con Flask
Lab 06 · Sistemas Operativos UCU
"""

from flask import Flask, jsonify
import datetime
import os

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({
        "app":     "Dummy B — Flask API",
        "version": "1.0.0",
        "lab":     "Lab 06 — DevOps UCU",
        "status":  "running"
    })

@app.route("/health")
def health():
    return jsonify({
        "status":    "ok",
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "service":   "dummy-b"
    }), 200

@app.route("/info")
def info():
    return jsonify({
        "hostname": os.uname().nodename,
        "python":   os.sys.version,
        "env":      os.environ.get("APP_ENV", "production")
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
