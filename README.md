# Fairfood Trace — Self-Hosted Monorepo

A self-hosted fork of [Fairfood's Trace platform](https://github.com/Fairfood) for supply chain traceability. Combines backend, dashboard, and admin into a single deployable stack.

## Architecture

```
fairfood-trace/
├── backend/                  # Django API (Trace-Server)
│   ├── fairtrace_v2/         # Django project root
│   ├── Dockerfile
│   └── entrypoint.sh
├── frontend/
│   ├── dashboard/            # Angular 15 — company dashboard
│   └── admin/                # Angular 16 — admin panel
├── config/
│   ├── .env.sample           # Docker env vars
│   └── secret.sample.ini     # Django secrets (INI format)
├── nginx/                    # Reverse proxy config
├── scripts/                  # Setup & utility scripts
├── docker-compose.yml        # Full stack orchestration
├── Makefile                  # Convenience commands
└── README.md
```

## Services

| Service      | Container       | Port  | Description                    |
|-------------|-----------------|-------|--------------------------------|
| API          | trace-api       | 8000  | Django REST backend            |
| Celery       | trace-celery    | —     | Background task worker         |
| Celery Beat  | trace-celery-beat| —    | Scheduled task runner          |
| PostgreSQL   | trace-db        | 5433  | Primary database               |
| Redis        | trace-redis     | 6380  | Cache + Celery broker          |
| Neo4j        | trace-neo4j     | 7475  | Graph DB (supply chain)        |
| Nginx        | trace-nginx     | 80    | Reverse proxy + static files   |

## Quick Start

```bash
# 1. Clone
git clone <this-repo> && cd fairfood-trace

# 2. Setup (creates configs, starts services, builds frontends)
make setup

# 3. Access
#    Dashboard:    http://localhost
#    Admin:        http://localhost/admin
#    API:          http://localhost/v2/
#    Django Admin: http://localhost/django-admin/
```

## Configuration

### `config/secret.ini`
Django reads this INI file for all secrets. Copy from `secret.sample.ini` and fill in:
- Database credentials (pre-filled for Docker defaults)
- Email SMTP settings
- S3-compatible storage credentials
- TOTP/OTP secrets

### `config/.env`
Docker Compose variables. Defaults work out of the box for local dev.

### Frontend Environments
Edit `frontend/dashboard/src/environments/environment.selfhosted.ts` and
`frontend/admin/src/environments/environment.selfhosted.ts` to set:
- Your domain/API URL
- OAuth client ID/secret (generate via Django admin after first boot)
- Google Maps API key (optional)

Then rebuild: `make build-frontend`

## What's Changed from Upstream

### Blockchain: Stubbed Out
The original Trace platform uses Hedera blockchain via a proprietary middleware (`bcmiddleware.cied.in`). This fork:
- Keeps blockchain models (required by DB schema / ForeignKeys)
- Makes all blockchain calls no-ops via `local.py` settings
- Removes Guardian celery beat tasks
- Sets explorer URLs to `#`

### Removed External Dependencies
- No calls to `*.fairfood.org` / `*.fairfood.nl` / `*.cied.in`
- No Sentry (disabled by default)
- S3 URL pattern changed from AWS-specific to generic
- Email FROM address configurable (was hardcoded `trace@fairfood.org`)

### Self-Hosted Additions
- `local.py` Django settings module
- `selfhosted` Angular build configurations
- Unified `docker-compose.yml` with all services
- Nginx reverse proxy serving both frontends + API
- Makefile for common operations
- Sample config files with documentation

## Common Commands

```bash
make up               # Start all services
make down             # Stop all services
make logs             # Tail logs
make logs-api         # Tail API logs only
make shell            # Django shell
make migrate          # Run migrations
make createsuperuser  # Create admin user
make build-frontend   # Rebuild Angular apps
make db-dump          # Backup database
make clean            # Nuclear option — removes everything
```

## S3-Compatible Storage (RustFS/MinIO)

To use your own S3-compatible storage, add to `config/secret.ini`:
```ini
[libs]
AWS_ACCESS_KEY_ID = your-key
AWS_SECRET_ACCESS_KEY = your-secret
AWS_STORAGE_BUCKET_NAME = trace-media
```

And in `backend/fairtrace_v2/fairtrace_v2/settings/local.py`, uncomment:
```python
AWS_S3_ENDPOINT_URL = "https://s3.your-domain.com"
```

## License

AGPL-3.0 — same as upstream Fairfood repos.
