#!/bin/bash
set -x

## Update and install general tools
sudo yum update -y

sudo yum install epel-release wget -y

cd /tmp/

## The following if-statements will install a version of erlang and rabbitmq working with centos9
## It may not work for other OS or even other versions of centos
## Check if erl(esl-erlang) exists, otherwise download it
if [ -f "/usr/bin/erl" ]; then
    echo "Erlang already exists. Skipping download."
else
    wget https://github.com/rabbitmq/erlang-rpm/releases/download/v26.2.5.3/erlang-26.2.5.3-1.el7.x86_64.rpm

    sudo yum -y install erlang-26.2.5.3-1.el7.x86_64.rpm
fi

## Install rabbitmq
if [ -f "/usr/sbin/rabbitmq-server" ]; then
    echo "Rabbitmq already exists. Skipping download."
else

    sudo rpm --import https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc
    wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.0.2/rabbitmq-server-4.0.2-1.el8.noarch.rpm

    sudo yum install -y rabbitmq-server-4.0.2-1.el8.noarch.rpm
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