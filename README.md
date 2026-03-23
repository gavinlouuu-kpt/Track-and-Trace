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
│   ├── dashboard/            # Angular 16 — company dashboard
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

| Service      | Container        | Port  | Description                    |
|-------------|------------------|-------|--------------------------------|
| API          | trace-api        | 8000  | Django REST backend            |
| Celery       | trace-celery     | —     | Background task worker         |
| Celery Beat  | trace-celery-beat| —     | Scheduled task runner          |
| PostgreSQL   | trace-db         | 5433  | Primary database               |
| Redis        | trace-redis      | 6380  | Cache + Celery broker          |
| Neo4j        | trace-neo4j      | 7475  | Graph DB (supply chain)        |
| Nginx        | trace-nginx      | 8090  | Reverse proxy + static files   |

## Prerequisites

Before you begin, make sure you have:

- **Docker Engine** 20.10+ and **Docker Compose** v2+ (check with `docker compose version`)
- **Git**
- **~4 GB free RAM** — Neo4j alone needs ~768 MB; the full stack needs ~3-4 GB
- The following **ports must be free** on your machine:

| Port | Used by     |
|------|-------------|
| 8090 | Nginx (main entry point) |
| 8000 | Django API  |
| 5433 | PostgreSQL  |
| 6380 | Redis       |
| 7475 | Neo4j HTTP  |
| 7688 | Neo4j Bolt  |

Check for conflicts: `ss -tlnp | grep -E '8090|8000|5433|6380|7475|7688'`

## Setup Guide

You can run `make setup` to do everything automatically, or follow the steps below manually if you want to understand what's happening.

### Step 1: Clone and Create Config Files

```bash
git clone <this-repo> && cd fairfood-trace

# Create config files from samples
cp config/.env.sample config/.env
cp config/secret.sample.ini config/secret.ini
```

Generate a random Django secret key and write it into `secret.ini`:

```bash
# Generate and insert a secret key
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))" 2>/dev/null \
  || openssl rand -base64 50 | tr -d '\n')
sed -i "s|your-django-secret-key-change-this|${SECRET_KEY}|g" config/secret.ini
```

**What's in each config file:**

`config/.env` — Docker Compose variables. Defaults work out of the box:
- `DJANGO_SETTINGS_MODULE` — always `fairtrace_v2.settings.local` for self-hosted
- `DJANGO_SUPERUSER_*` — auto-created admin account (default: `admin` / `admin123`)
- `POSTGRES_*` — database credentials (must match `secret.ini`)

`config/secret.ini` — Django reads this at runtime. Key sections:
- `[app]` — URLs, deployment mode, `SECRET_KEY`
- `[database]` — DB, Redis, Neo4j connection info (defaults match docker-compose)
- `[email]` — SMTP settings (configure if you need email notifications)
- `[libs]` — S3 storage, OAuth credentials, API keys
- `[blockchain]` / `[guardian]` — stubbed out, leave as-is

For local development, the only required change is the `SECRET_KEY` (done above). Everything else has working defaults.

### Step 2: Start Infrastructure Services

```bash
docker compose up -d db redis graphdb
```

Wait for PostgreSQL to be ready:

```bash
# Check health (should say "accepting connections")
docker compose exec db pg_isready -U trace_user
```

This starts:
- **PostgreSQL** on port 5433 — primary database for Django models
- **Redis** on port 6380 — cache layer and Celery message broker
- **Neo4j** on port 7475 — graph database for supply chain relationships

### Step 3: Build and Start the Backend

```bash
docker compose up -d api celery celery-beat
```

The first run takes a few minutes because Docker builds the backend image (Python 3.8, installs all pip dependencies).

The `entrypoint.sh` script runs automatically on the `api` container and handles:
1. Waiting for PostgreSQL to be reachable
2. Running all Django migrations (`manage.py migrate`)
3. Collecting static files
4. Creating the superuser from `DJANGO_SUPERUSER_*` env vars in `.env`

Watch the progress:

```bash
docker compose logs -f api
```

You should see `Superuser ready: admin` followed by the Django dev server starting on port 8000.

### Step 4: Build the Frontends

The frontends are Angular 16 apps. They're built inside Docker containers using Node 18:

```bash
# Build the dashboard (takes 2-5 minutes on first run)
docker compose --profile build run --rm dashboard-build

# Build the admin panel
docker compose --profile build run --rm admin-build
```

This runs `npm install && npm run build` inside each container. The build output goes to:
- `frontend/dashboard/dist/fairfood-trace-dashboard/`
- `frontend/admin/dist/fairfood-admin/`

These directories are mounted into the Nginx container as static files.

**Alternative: Build locally** (if you prefer not to use Docker for frontend builds):

```bash
# Requires Node 18+
cd frontend/dashboard && npm install && npm run build && cd ../..
cd frontend/admin && npm install && npm run build && cd ../..
```

### Step 5: Start Nginx

```bash
docker compose up -d nginx
```

Nginx serves as the single entry point on port **8090**, routing:
- `/` → Dashboard frontend
- `/admin/` → Admin frontend
- `/v2/`, `/api/`, `/o/`, `/django-admin/` → Django API backend
- `/static/` → Django static files

### Step 6: Verify Everything is Running

```bash
# All containers should show "Up"
docker compose ps

# Test the API
curl -s http://localhost:8090/v2/ | head -20

# Test the dashboard
curl -s -o /dev/null -w "%{http_code}" http://localhost:8090/
# Should return 200
```

Visit in your browser:
- **Dashboard**: http://localhost:8090
- **Admin panel**: http://localhost:8090/admin
- **Django admin**: http://localhost:8090/django-admin/ (login: `admin` / `admin123`)
- **API root**: http://localhost:8090/v2/
- **Neo4j browser**: http://localhost:7475 (login: `neo4j` / `trace_neo4j_pass`)

## Post-Setup: Configure OAuth for Login

The Dashboard and Admin frontends use OAuth2 to authenticate with the backend. Without this step, **you won't be able to log in** through the frontend apps (Django admin will still work).

### 1. Create an OAuth Application

1. Go to http://localhost:8090/django-admin/ and log in with `admin` / `admin123`
2. Navigate to **Django OAuth Toolkit** → **Applications** → **Add Application**
3. Fill in:
   - **User**: select the admin user (ID 1)
   - **Client type**: `Confidential`
   - **Authorization grant type**: `Authorization code`
   - **Redirect uris** (one per line):
     ```
     http://localhost:8090/
     http://localhost:8090/admin/
     ```
   - **Name**: `Trace Frontend` (or any name)
4. Click **Save**
5. Copy the generated **Client id** and **Client secret**

### 2. Update Configuration with OAuth Credentials

Add the credentials to `config/secret.ini`:

```ini
[libs]
TRACE_OAUTH2_CLIENT_ID = <paste client id>
TRACE_OAUTH2_CLIENT_SECRET = <paste client secret>
```

Update the frontend environment files:

**`frontend/dashboard/src/environments/environment.selfhosted.ts`**:
```typescript
export const clientId = '<paste client id>';
export const clientSecret = '<paste client secret>';
```

**`frontend/admin/src/environments/environment.selfhosted.ts`**:
```typescript
export const clientId = '<paste client id>';
export const clientSecret = '<paste client secret>';
```

### 3. Rebuild Frontends and Restart

```bash
make build-frontend
docker compose restart nginx
```

You should now be able to log in through the Dashboard and Admin UIs.

## Deploying to a Remote Server

When deploying to a server (not localhost):

1. **Update URLs** — Replace `localhost` / `100.81.210.49` with your domain in:
   - `config/secret.ini` → `[app]` section (`ROOT_URL`, `FRONT_ROOT_URL`, etc.)
   - `frontend/dashboard/src/environments/environment.selfhosted.ts` → `API_URL`, `authUrl`
   - `frontend/admin/src/environments/environment.selfhosted.ts` → `API_URL`, `authUrl`, `traceUrl`
   - OAuth redirect URIs in Django admin

2. **Rebuild frontends** after changing environment files:
   ```bash
   make build-frontend
   docker compose restart nginx
   ```

3. **HTTPS** — The built-in Nginx serves HTTP on port 8090. For production, put an HTTPS-terminating reverse proxy in front (e.g., Caddy, Traefik, or Nginx with certbot):
   ```
   Internet → HTTPS proxy (:443) → trace-nginx (:8090) → services
   ```

4. **Change default passwords** in `config/.env` and `config/secret.ini`:
   - `DJANGO_SUPERUSER_PASSWORD`
   - `POSTGRES_PASSWORD` (also update `[database]` section in `secret.ini`)
   - `NEO4J_PASSWORD` (also update in `docker-compose.yml` → `NEO4J_AUTH`)

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

## Common Commands

```bash
make setup              # First-time setup (creates configs, starts everything)
make up                 # Start all services
make down               # Stop all services
make logs               # Tail all logs
make logs-api           # Tail API logs only
make logs-celery        # Tail Celery logs
make shell              # Django shell
make migrate            # Run Django migrations
make createsuperuser    # Create admin user
make build-frontend     # Rebuild Angular apps
make db-dump            # Backup database to backup.sql
make db-restore         # Restore database from backup.sql
make clean              # Remove all containers, volumes, and build artifacts
```

## Troubleshooting

### Port conflicts
If a port is already in use, change the host-side port mapping in `docker-compose.yml`:
```yaml
ports:
  - "9090:80"   # Change 8090 to 9090 for Nginx
```

### Neo4j out of memory
Reduce heap size in `docker-compose.yml` under the `graphdb` service:
```yaml
NEO4J_dbms_memory_heap_max__size: 256M  # Lower from 512M
```

### Frontend build fails
- Check Node version: the Docker build uses Node 18. If building locally, ensure `node -v` shows 18+
- Delete `node_modules` and retry: `rm -rf frontend/dashboard/node_modules && make build-frontend`
- Check for npm errors in the build output

### Can't log in through Dashboard / Admin
- Verify you completed the [OAuth setup](#post-setup-configure-oauth-for-login)
- Check that `clientId` and `clientSecret` in the frontend environment files match the OAuth application in Django admin
- Rebuild frontends after changing environment files

### API returns 500 errors
```bash
make logs-api    # Check the error traceback
```
Common causes:
- `secret.ini` values don't match `docker-compose.yml` (database credentials, Redis URL)
- Missing migrations: run `make migrate`

### Database connection errors
Verify that `[database]` section in `config/secret.ini` matches the Docker environment:
- `DB_HOST = db` (not `localhost` — containers use Docker networking)
- `DB_PORT = 5432` (internal port, not 5433)
- Credentials match `POSTGRES_*` in `config/.env`

### Containers keep restarting
```bash
docker compose logs <service-name>   # Check what's failing
docker compose ps                     # See container states
```

## Known Version Issues

This project was forked from an older codebase with pinned dependencies. Several version incompatibilities exist that you may encounter during builds or at runtime.

### Backend (Python)

#### Python 3.8 vs package requirements

The Dockerfile uses **Python 3.8.13**, but several pinned packages require Python 3.9+:

| Package | Pinned Version | Issue | Fix |
|---------|---------------|-------|-----|
| `pandas` | 2.0.3 | Requires Python 3.9+ | Downgrade to `pandas==1.5.3` |
| `pyspark` | 3.4.1 | Requires Python 3.9+ | Downgrade to `pyspark==3.2.3` or remove if unused |
| `Pillow` | 10.0.0 | Last version with 3.8 support, but at the edge | Downgrade to `Pillow==9.5.0` for safety |

These are in `backend/requirements/base.txt`. If the backend Docker build fails with pip resolution errors, these are the most likely cause.

#### Outdated packages with Python 3.8 compatibility issues

| Package | Pinned Version | Issue | Fix |
|---------|---------------|-------|-----|
| `greenlet` | 0.4.15 | Does not support Python 3.8 | Upgrade to `greenlet==1.1.3` |
| `gevent` | 1.4.0 | Too old for Python 3.8 | Upgrade to `gevent==21.12.0` |
| `gunicorn` | 19.9.0 | Pre-dates Python 3.8 | Upgrade to `gunicorn==20.1.0` |
| `keyring` | 11.0.0 | Too old for Python 3.8 | Upgrade to `keyring==23.13.1` |

These are in `backend/requirements/local.txt` and `development.txt`.

#### Celery and pip compatibility

`celery==4.4.2` has broken metadata that causes install failures with pip 24.1+. The Dockerfile already works around this by capping pip:
```dockerfile
RUN pip install --upgrade "pip<24.1"
```

If you upgrade pip, Celery will fail to install.

#### Duplicate/conflicting pins in base.txt

`backend/requirements/base.txt` has some redundant entries:
- `tqdm==4.64.1` (line 55) AND `tqdm>=4.64.0` (line 58)
- `geopy==2.3.0` (line 56) AND `geopy>=2.2.0` (line 61)
- `lat-lon-parser==1.3.0` (line 57) AND `lat-lon-parser>=1.3.0` (line 62)

These don't break the build but may cause confusion.

#### Unpinned git dependency

`backend/requirements/base.txt` references a git repo with no version pin:
```
git+https://github.com/cied/django-neomodel.git
```
If this repo is removed or has breaking changes, the build will fail. Consider vendoring a known-good version.

### Frontend (Angular/Node)

#### Node version

Angular 16 officially supports **Node 16.14+ or 18.10+**. The docker-compose build containers use `node:18-alpine` which works. If building locally, ensure you're on Node 16 or 18 (not 20+, which may have issues with Angular 16).

#### Local `.tgz` dependencies

Both frontends depend on locally bundled packages:

**Dashboard** (`frontend/dashboard/package.json`):
```json
"fairfood-form-components": "file:fairfood-form-components-0.2.6.tgz"
"fairfood-utils": "file:fairfood-utils-0.3.3.tgz"
```

**Admin** (`frontend/admin/package.json`):
```json
"fairfood-form-components": "file:fairfood-form-components-0.2.2.tgz"
"fairfood-utils": "file:fairfood-utils-0.3.3.tgz"
```

If these `.tgz` files are missing (e.g., not committed to git or excluded by `.gitignore`), `npm install` will fail. Verify they exist:
```bash
ls frontend/dashboard/*.tgz frontend/admin/*.tgz
```

Note: The dashboard directory also contains older versions (`fairfood-form-components-0.0.9.tgz`, `fairfood-utils-0.1.1.tgz`) that are unused and can be safely removed.

#### TypeScript version mismatch

The dashboard uses **TypeScript 4.9.4** while the admin uses **TypeScript 5.1.6**. This doesn't prevent builds (they build independently), but be aware of it if sharing code between the two apps.

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
