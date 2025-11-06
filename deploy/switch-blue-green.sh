#!/usr/bin/env bash
set -e
TARGET=$1  # "blue" or "green"
if [ "$TARGET" = "green" ]; then PORT=8082; else PORT=8081; fi
sudo sed -i "s|proxy_pass http://localhost:[0-9]\+|proxy_pass http://localhost:${PORT}|" /etc/nginx/sites-available/devops-proxy
sudo nginx -t
sudo systemctl reload nginx
echo "✅ Switched live traffic to $TARGET (port $PORT)"
