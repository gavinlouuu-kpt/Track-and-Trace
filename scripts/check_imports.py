#!/usr/bin/env python3
"""Check all imports and find missing packages."""
import subprocess
import sys

# Packages we know are needed based on codebase analysis
EXTRA_PACKAGES = [
    'tqdm',
    'django-oauth-toolkit',
    'oauth2_provider',
]

# Install missing ones
for pkg in EXTRA_PACKAGES:
    subprocess.run([sys.executable, '-m', 'pip', 'install', pkg], 
                   capture_output=True)

import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fairtrace_v2.settings.local')

try:
    import django
    django.setup()
    print("SUCCESS: Django loaded all apps")
except Exception as e:
    print(f"FAILED: {e}")
    sys.exit(1)
