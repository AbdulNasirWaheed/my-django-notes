FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=notesapp.settings

WORKDIR /app

# No system packages needed here unless requirements.txt pulls in something
# that requires compiling (e.g. mysqlclient or psycopg2 without the -binary
# variant). This project's requirements.txt (Django, DRF, gunicorn, whitenoise,
# etc.) has no such dependency, so we skip apt-get entirely to keep the image
# small and the build fast.

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/').read()" || exit 1

# Single worker, small thread pool — tuned for a small (1GB RAM) instance.
# Bump --workers once you move to a bigger instance.
CMD ["gunicorn", "notesapp.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "1", "--threads", "2", "--timeout", "60"]
