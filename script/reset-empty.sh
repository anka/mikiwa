#!/usr/bin/env bash
# Mikiwa – Reset Database (empty)
# Drops, recreates and migrates the database. No seeds.
set -euo pipefail

cd "$(dirname "$0")/.."

RAILS_ENV="${RAILS_ENV:-development}"
export RAILS_ENV

echo "Resetting database (RAILS_ENV=$RAILS_ENV)..."
bin/rails db:drop db:create db:migrate
echo "Done. Database is empty."
