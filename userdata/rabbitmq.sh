#!/bin/bash
set -uxo pipefail

cd /tmp/

## Configure the yum repositories
cp /vagrant/rabbitmq.repo /etc/yum.repos.d/.
dnf update -y


## Install dependencies
sudo dnf install -y socat logrotate

sudo dnf install -y erlang rabbitmq-server

## Start and enable the service
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server

## Creating the rabbitmq config file
echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

## Creating user with user privileges

user_exists=$(sudo rabbitmqctl list_users | grep "test")

if [[ -z "$user_exists" ]]; then
    ## User doesn't exist, create it
    rabbitmqctl add_user test test
    rabbitmqctl set_user_tags test administrator
    echo "User test created successfully"
else
    ## User already exists, skip creation
    echo "User test already exists, skipping creation"
fi

sudo systemctl restart rabbitmq-server
sudo systemctl status rabbitmq-server

## Set firewalls for rabbitmq
sudo systemctl start firewalld
sudo systemctl enable firewalld
firewall-cmd --zone=public --add-port=4369/tcp --add-port=5672/tcp --add-port=25672/tcp
firewall-cmd --runtime-to-permanent