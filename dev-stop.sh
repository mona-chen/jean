#!/bin/bash
# Development Environment Stop Script
# Stops all development services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Stopping development environment..."

docker compose -f docker-compose.dev.yml down --volumes --remove-orphans

echo ""
echo "Development environment stopped."
echo "Note: PostgreSQL and Redis data volumes have been removed."
echo "To preserve data, run 'docker compose -f docker-compose.dev.yml down' (without --volumes)"
