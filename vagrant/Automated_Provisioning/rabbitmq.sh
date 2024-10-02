#!/bin/bash
set -euxo pipefail

cd /tmp/

## Check if erl(esl-erlang) exists, otherwise download it
if [ -f "/usr/bin/erl" ]; then
    echo "Erlang already exists. Skipping download."
else
    wget https://packages.erlang-solutions.com/erlang/rpm/centos/7/x86_64/esl-erlang_24.0.2-1~centos~7_amd64.rpm

    sudo yum -y install esl-erlang_24.0.2-1~centos~7_amd64.rpm
fi

## Install rabbitmq
if [ -f "/usr/sbin/rabbitmq-server" ]; then
    echo "Rabbitmq already exists. Skipping download."
else
    wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.19/rabbitmq-server-3.8.19-1.el7.noarch.rpm

    sudo yum install -y rabbitmq-server-3.8.19-1.el7.noarch.rpm
fi



## Install dependencies
sudo yum install -y socat logrotate

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