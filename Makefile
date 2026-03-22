.PHONY: help setup up down build-frontend restart logs shell migrate createsuperuser clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## First-time setup (creates configs, starts everything)
	chmod +x scripts/setup.sh && ./scripts/setup.sh

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

build-frontend: ## Build frontend apps
	docker compose --profile build run --rm dashboard-build
	docker compose --profile build run --rm admin-build

build-backend: ## Rebuild backend container
	docker compose build api

logs: ## Tail all logs
	docker compose logs -f

logs-api: ## Tail API logs
	docker compose logs -f api

logs-celery: ## Tail Celery logs
	docker compose logs -f celery celery-beat

shell: ## Django shell
	docker compose exec api python fairtrace_v2/manage.py shell_plus

migrate: ## Run Django migrations
	docker compose exec api python fairtrace_v2/manage.py migrate

createsuperuser: ## Create Django superuser
	docker compose exec api python fairtrace_v2/manage.py createsuperuser

collectstatic: ## Collect static files
	docker compose exec api python fairtrace_v2/manage.py collectstatic --noinput

clean: ## Remove all containers, volumes, and build artifacts
	docker compose down -v --remove-orphans
	docker compose --profile build down -v

db-shell: ## PostgreSQL shell
	docker compose exec db psql -U trace_user -d trace_db

db-dump: ## Dump database to backup.sql
	docker compose exec db pg_dump -U trace_user trace_db > backup.sql

db-restore: ## Restore database from backup.sql
	cat backup.sql | docker compose exec -T db psql -U trace_user -d trace_db
