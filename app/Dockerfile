# Small official Python base image. "slim" leaves out extras the app doesn't need,
# which means fewer packages to patch and a smaller attack surface.
FROM python:3.12-slim

# Work inside /app in the container, not in the root directory.
WORKDIR /app

# Copy requirements first, on their own. Docker caches each step, so if only
# app.py changes, the slow pip install step is reused from cache.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code last, since it changes most often.
COPY app.py .

# Don't run the app as root. If the app is compromised, the attacker gets
# a low-privilege user instead of full control of the container.
RUN useradd --create-home --uid 10001 appuser
USER 10001

EXPOSE 8080

# Start the app. The exec form (JSON array) lets the app receive shutdown signals directly.
CMD ["python", "app.py"]
