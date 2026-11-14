from flask import Flask, jsonify
import os
import socket
import json
import boto3
import psycopg2

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

@app.route("/db")
def db_check():
    # Read the password from Secrets Manager at request time. It is never
    # stored in the image, the environment, or the logs.
    secret = boto3.client("secretsmanager", region_name=os.environ["AWS_REGION"])
    creds = json.loads(
        secret.get_secret_value(SecretId=os.environ["DB_SECRET_ARN"])["SecretString"]
    )
    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=creds["username"],
        password=creds["password"],
        connect_timeout=5,
    )
    with conn, conn.cursor() as cur:
        cur.execute("SELECT 1")
        result = cur.fetchone()[0]
    conn.close()
    return jsonify(database="ok", result=result)

if __name__ == "__main__":
    # 0.0.0.0 means "listen on all network interfaces", needed inside a container.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
