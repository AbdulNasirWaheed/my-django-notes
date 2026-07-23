# ---------- Build stage ----------
FROM python:3.10-slim AS builder

WORKDIR /app

# System deps needed only to build Python packages (e.g. psycopg2 from source)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies into a separate prefix so we can copy just the
# installed packages into the final image, leaving build tools behind.
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ---------- Final stage ----------
FROM python:3.10-slim

# Prevents .pyc files and enables unbuffered stdout/stderr (for docker logs)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=notesapp.settings

WORKDIR /app

# Runtime-only system dependency (libpq needed to actually connect to Postgres,
# but not the compiler toolchain used to build psycopg2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Bring in the packages built in the previous stage — no gcc/libpq-dev bloat here
COPY --from=builder /install /usr/local

# Copy application code last so code-only changes don't invalidate the
# dependency-install layers above
COPY . .

# Run as a non-root user
RUN useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Basic container-level healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request,sys; urllib.request.urlopen('http://localhost:8000/').read()" || exit 1

# Production server — do NOT use manage.py runserver in production
CMD ["gunicorn", "notesapp.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
