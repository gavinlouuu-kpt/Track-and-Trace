"""Settings for self-hosted deployment.

Stubs out blockchain/Guardian, uses local/S3-compatible storage,
and removes all Fairfood proprietary domain references.
"""
import os

from .base import *  # noqa: F403, F401
from .base import BASE_DIR
from .base import config

DEBUG = True

ENVIRONMENT = "local"
DEPLOYMENT = "local"

# ── Hosts ──────────────────────────────────────────────────────
ALLOWED_HOSTS = ["*"]

CORS_ORIGIN_ALLOW_ALL = True
CORS_ORIGIN_WHITELIST = [
    "http://localhost",
    "http://localhost:4200",
    "http://localhost:4300",
    "http://localhost:8000",
    "http://127.0.0.1",
]

# ── URLs (self-hosted, no Fairfood domains) ────────────────────
FRONT_ROOT_URL = config.get(
    "app", "FRONT_ROOT_URL", fallback="http://localhost"
)

# ── Static files ───────────────────────────────────────────────
STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(os.path.dirname(BASE_DIR), "static")

# ── Media / S3-compatible storage ──────────────────────────────
AWS_ACCESS_KEY_ID = config.get("libs", "AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = config.get("libs", "AWS_SECRET_ACCESS_KEY")
AWS_STORAGE_BUCKET_NAME = config.get(
    "libs", "AWS_STORAGE_BUCKET_NAME", fallback="trace-media"
)
AWS_QUERYSTRING_AUTH = False
AWS_PRELOAD_METADATA = True

# For S3-compatible backends (RustFS, MinIO, etc.), override these:
# AWS_S3_ENDPOINT_URL = "https://s3.your-domain.com"
# AWS_S3_REGION_NAME = "us-east-1"
# AWS_S3_CUSTOM_DOMAIN = "s3.your-domain.com/trace-media"

DEFAULT_FILE_STORAGE = "s3_folder_storage.s3.DefaultStorage"
DEFAULT_S3_PATH = "media"
MEDIA_ROOT = "/%s/" % DEFAULT_S3_PATH
MEDIA_URL = "/media/"

# ── Email ──────────────────────────────────────────────────────
# Override FROM_EMAIL from base.py (which hardcodes trace@fairfood.org)
FROM_EMAIL = config.get("email", "FROM_EMAIL", fallback="Trace <noreply@localhost>")

# ── Sentry (disabled by default for self-hosted) ──────────────
SENTRY_DSN = config.get("libs", "SENTRY_DSN", fallback="")
if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration
    sentry_sdk.init(dsn=SENTRY_DSN, integrations=[DjangoIntegration()])

# ── Blockchain (stubbed out) ──────────────────────────────────
# BC_MIDDLEWARE_BASE_URL is set in base.py. Override to a dummy (must be non-empty to pass assert).
BC_MIDDLEWARE_BASE_URL = "http://blockchain-stub-disabled/"

# Hedera explorers - make them no-ops
HEDERA_ACCOUNT_EXPLORER = "#"
HEDERA_TRANSACTION_EXPLORER = "#"
TOPL_TRANSACTION_EXPLORED = "#"
HEDERA_NETWORK = 1

# Topic IDs (required by model but never called)
HEDERA_CLAIM_TOPIC_ID = "0.0.0"
HEDERA_TRANSACTION_TOPIC_ID = "0.0.0"

# ── Guardian (disabled) ───────────────────────────────────────
# Remove guardian celery beat tasks
CELERY_BEAT_SCHEDULE.pop("check-guardian-claim-status", None)  # noqa: F405
CELERY_BEAT_SCHEDULE.pop("validate_and_initiate_guardian_claim", None)  # noqa: F405

# ── Timezone ───────────────────────────────────────────────────
TIME_ZONE = "UTC"
