#!/bin/bash
set -e

echo "Deploying Agendity..."

# Pull latest code
git pull origin main

# Build and start containers
docker compose build
docker compose up -d

# Run migrations
docker compose exec api bundle exec rails db:migrate

# Seed if first deploy
# docker compose exec api bundle exec rails db:seed

echo "Deploy complete!"
echo "App: http://localhost"
echo "Admin: http://localhost/admin"
