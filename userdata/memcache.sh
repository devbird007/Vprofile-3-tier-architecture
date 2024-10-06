#!/bin/bash
set -euxo pipefail

## Install memcached and its dependencies
sudo yum install memcached -y
sudo dnf --enablerepo=crb install libmemcached-awesome -y

sudo systemctl start memcached
sudo systemctl enable memcached

## Configuring the firewalld for memcached
sudo systemctl start firewalld
sudo systemctl enable firewalld

firewall-cmd --add-port=11211/tcp
firewall-cmd --add-port=11111/udp
firewall-cmd --runtime-to-permanent

## Running memcached
sudo memcached -p 11211 -U 11111 -u memcached -d