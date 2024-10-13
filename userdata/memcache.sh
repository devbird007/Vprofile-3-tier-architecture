#!/bin/bash
set -x

# Update the server
sudo yum update -y
sudo yum install epel-release -y

## Install memcached and its dependencies
sudo yum install memcached -y
sudo dnf --enablerepo=crb install libmemcached-awesome -y

sudo systemctl start memcached
sudo systemctl enable memcached

## This configures external access for memcached
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
sudo systemctl restart memcached
## Running memcached
sudo memcached -p 11211 -U 11111 -u memcached -d