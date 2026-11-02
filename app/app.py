from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.route("/")
def index():
    # Shows which container answered. Useful once several instances sit
    # behind the load balancer on Day 3e, so you can see traffic spread out.
    return f"Hello from {socket.gethostname()}\n"

@app.route("/health")
def health():
    # The load balancer calls this URL to decide whether an instance is healthy.
    return jsonify(status="ok")

if __name__ == "__main__":
    # 0.0.0.0 means "listen on all network interfaces", needed inside a container.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
