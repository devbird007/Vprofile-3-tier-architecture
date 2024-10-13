#!/bin/bash
set -x

# Update the server
sudo yum update -y
sudo yum install epel-release -y

DATABASE_PASS='admin123'

## Installing mariadb
sudo yum install mariadb-server git -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

## Configuring mariadb with secure installations
### Set password for root user
sudo mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$DATABASE_PASS')"
### Delete anonymous users
sudo mysql -u root -p$DATABASE_PASS -e "DELETE FROM mysql.user WHERE User=''"
### Disable remote root user login
sudo mysql -u root -p$DATABASE_PASS -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
### Delete the test database
sudo mysql -u root -p$DATABASE_PASS -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
### Ensure changes take effect
sudo mysql -u root -p$DATABASE_PASS -e "FLUSH PRIVILEGES"

## Downloading the source code and initializing the database
cd /tmp/
git clone -b aws-lift-and-shift https://github.com/devbird007/Vprofile-3-tier-architecture.git

sudo mysql -u root -p"$DATABASE_PASS" -e "create database accounts"
# POSSIBLE POINT OF ERROR
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'%' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'localhost' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" accounts < Vprofile-3-tier-architecture/src/main/resources/db_backup.sql
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

## Restarting mariadb-server
sudo systemctl restart mariadb



# NO FIREWALLS NEEDED since AWS Security Groups already provide instance-level security.
# For the firewalls configs, run `git checkout euro-linux-centos-automated-setup` for
# the automated local setup on vagrant with centos9 which contains the firewall-configs in their scripts
# for each service