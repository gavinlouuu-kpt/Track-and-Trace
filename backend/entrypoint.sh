#!/bin/sh
set -e

echo "Waiting for PostgreSQL..."
while ! nc -z ${SQL_HOST:-db} ${SQL_PORT:-5432} 2>/dev/null; do
  sleep 0.5
done
echo "PostgreSQL started"

cd /usr/src/app/fairtrace_v2

# Run migrations
python manage.py migrate --noinput

# Collect static files
python manage.py collectstatic --noinput 2>/dev/null || true

# Create superuser if env vars are set
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_EMAIL" ]; then
    python manage.py createsuperuser \
        --noinput \
        --username "$DJANGO_SUPERUSER_USERNAME" \
        --email "$DJANGO_SUPERUSER_EMAIL" 2>/dev/null || true
    echo "Superuser ready: $DJANGO_SUPERUSER_USERNAME"
fi

exec "$@"
