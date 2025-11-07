#!/bin/bash
set -e

ENV=$1
echo "Switching traffic to $ENV..."

if [ "$ENV" = "green" ]; then
  docker exec nginx-container sh -c "cp /etc/nginx/conf.d/green.conf /etc/nginx/conf.d/default.conf && nginx -s reload"
  echo "✅ Switched live traffic to GREEN (port 5001)"
else
  docker exec nginx-container sh -c "cp /etc/nginx/conf.d/blue.conf /etc/nginx/conf.d/default.conf && nginx -s reload"
  echo "✅ Switched live traffic to BLUE (port 8081)"
fi

