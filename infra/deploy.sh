#!/usr/bin/env bash
# ============================================================================
# BEE FACTORY — Deploy backend to Fly.io (free tier)
#
# Prerequisites:
#   1. Install flyctl:  curl -L https://fly.io/install.sh | sh
#   2. Sign up:         fly auth signup
#   3. Login:           fly auth login
#
# First-time setup (run once):
#   ./deploy.sh setup
#
# Deploy:
#   ./deploy.sh deploy
#
# The app will be available at:
#   https://beefactory-api.fly.dev
# ============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

APP_NAME="beefactory-api"
REGION="fra"

case "${1:-deploy}" in
  setup)
    echo "=== Setting up Fly.io app ==="

    # Create the app
    fly apps create "$APP_NAME" --org personal 2>/dev/null || echo "App already exists"

    # Create Postgres cluster (free tier: 1 shared CPU, 256MB, 1GB storage)
    echo "Creating Postgres database..."
    fly postgres create \
      --name "${APP_NAME}-db" \
      --region "$REGION" \
      --vm-size shared-cpu-1x \
      --initial-cluster-size 1 \
      --volume-size 1 \
      2>/dev/null || echo "Database already exists"

    # Attach Postgres to the app (sets DATABASE_URL secret automatically)
    fly postgres attach "${APP_NAME}-db" --app "$APP_NAME" \
      2>/dev/null || echo "Database already attached"

    # Set secrets
    echo "Setting secrets..."
    fly secrets set \
      JWT_SECRET="$(openssl rand -base64 32)" \
      NODE_ENV="production" \
      --app "$APP_NAME"

    echo ""
    echo "=== Setup complete ==="
    echo "Now run: ./deploy.sh deploy"
    echo ""
    echo "Your API will be at: https://${APP_NAME}.fly.dev"
    echo "Swagger docs at:     https://${APP_NAME}.fly.dev/api"
    ;;

  deploy)
    echo "=== Deploying to Fly.io ==="
    cd "$SCRIPT_DIR"
    fly deploy --config fly.toml --dockerfile "$ROOT_DIR/services/api_backend/Dockerfile" --app "$APP_NAME"

    echo ""
    echo "=== Deployed ==="
    echo "API:     https://${APP_NAME}.fly.dev"
    echo "Swagger: https://${APP_NAME}.fly.dev/api"
    echo "WebSocket: wss://${APP_NAME}.fly.dev/chat"
    ;;

  logs)
    fly logs --app "$APP_NAME"
    ;;

  status)
    fly status --app "$APP_NAME"
    ;;

  *)
    echo "Usage: $0 {setup|deploy|logs|status}"
    exit 1
    ;;
esac
