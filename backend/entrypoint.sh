#!/bin/sh
set -e

echo "Waiting for PostgreSQL..."
while ! nc -z $SQL_HOST $SQL_PORT 2>/dev/null; do
  sleep 0.5
done
echo "PostgreSQL started"

# Run migrations
python fairtrace_v2/manage.py migrate --noinput

# Collect static files
python fairtrace_v2/manage.py collectstatic --noinput 2>/dev/null || true

# Create superuser if env vars are set
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_EMAIL" ]; then
    python fairtrace_v2/manage.py createsuperuser \
        --noinput \
        --username "$DJANGO_SUPERUSER_USERNAME" \
        --email "$DJANGO_SUPERUSER_EMAIL" 2>/dev/null || true
    echo "Superuser ready: $DJANGO_SUPERUSER_USERNAME"
fi

exec "$@"
