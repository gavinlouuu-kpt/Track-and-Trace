#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════════════╗"
echo "║  Fairfood Trace - Self-Hosted Setup          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_DIR"

# ── 1. Create config files from samples ────────────────────────
if [ ! -f config/.env ]; then
    cp config/.env.sample config/.env
    echo "✓ Created config/.env (edit with your values)"
else
    echo "• config/.env already exists, skipping"
fi

if [ ! -f config/secret.ini ]; then
    cp config/secret.sample.ini config/secret.ini
    # Generate a random Django secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))" 2>/dev/null || openssl rand -base64 50 | tr -d '\n')
    sed -i "s|your-django-secret-key-change-this|${SECRET_KEY}|g" config/secret.ini
    echo "✓ Created config/secret.ini with random SECRET_KEY (edit remaining values)"
else
    echo "• config/secret.ini already exists, skipping"
fi

# ── 2. Start infrastructure services ──────────────────────────
echo ""
echo "Starting database services..."
docker compose up -d db redis graphdb
echo "Waiting for PostgreSQL to be ready..."
sleep 5
docker compose exec db pg_isready -U trace_user || sleep 5

# ── 3. Build and start backend ────────────────────────────────
echo ""
echo "Building and starting backend..."
docker compose up -d api celery celery-beat

echo "Waiting for migrations..."
sleep 10

# ── 4. Build frontends ────────────────────────────────────────
echo ""
echo "Building frontend apps (this may take a few minutes)..."
docker compose --profile build run --rm dashboard-build
docker compose --profile build run --rm admin-build

# ── 5. Start Nginx ────────────────────────────────────────────
echo ""
echo "Starting Nginx..."
docker compose up -d nginx

# ── 6. Generate OAuth credentials ─────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Setup Complete!                             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Services running:"
echo "  • Dashboard:    http://localhost"
echo "  • Admin:        http://localhost/admin"
echo "  • API:          http://localhost/v2/"
echo "  • Django Admin: http://localhost/django-admin/"
echo "  • Neo4j:        http://localhost:7475"
echo ""
echo "Next steps:"
echo "  1. Edit config/secret.ini with your email/storage settings"
echo "  2. Create OAuth app via Django admin for frontend auth"
echo "  3. Update frontend environment files with OAuth credentials"
echo "  4. Rebuild frontends: docker compose --profile build run --rm dashboard-build"
echo ""
