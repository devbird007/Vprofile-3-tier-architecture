#!/bin/bash
set -euxo pipefail

## Installing Nginx
sudo apt update -y
sudo apt install nginx -y

## Configuring nginx
sudo cat <<EOF > /etc/nginx/sites-available/vproapp
upstream vproapp {
    server app01:8080;
}
server {
    listen 80;
    location / {
        proxy_pass http://vproapp;
    }
}
EOF

sudo unlink /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp

sudo systemctl enable nginx
sudo systemctl restart nginx