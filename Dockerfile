# ---------- Build stage ----------
# Installs Python dependencies into an isolated prefix so the final image
# doesn't carry pip's cache, wheel build artifacts, or any build-only tools.
FROM python:3.10-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ---------- Final stage ----------
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=notesapp.settings

WORKDIR /app

# Bring in only the installed packages from the builder stage — no pip cache,
# no leftover build tooling, keeping the final image lean.
COPY --from=builder /install /usr/local

COPY . .

RUN useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/').read()" || exit 1

# Single worker, small thread pool — tuned for a small (1GB RAM) instance,
# and avoids SQLite "database is locked" issues from concurrent writers.
# Bump --workers once you move to a bigger instance.
CMD ["gunicorn", "notesapp.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "1", "--threads", "2", "--timeout", "60"]
