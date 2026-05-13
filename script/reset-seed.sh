#!/usr/bin/env bash
# Mikiwa – Reset Database (with seeds)
# Drops, recreates, migrates and seeds the database.
set -euo pipefail

cd "$(dirname "$0")/.."

RAILS_ENV="${RAILS_ENV:-development}"
export RAILS_ENV

echo "Resetting database with seeds (RAILS_ENV=$RAILS_ENV)..."
DEMO=1 bin/rails db:drop db:create db:migrate db:seed
echo "Done. Database is seeded."
