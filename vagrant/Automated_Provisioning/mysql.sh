#!/bin/bash
set -euxo pipefail

#Configuring the /etc/yum.repos.d/CentOS-Base.repo file

OLD_MIRROR="mirrorlist=http"
NEW_MIRROR="#$OLD_MIRROR"
OLD_BASEURL="#baseurl=http"
NEW_BASEURL="${OLD_BASEURL:1}"
OLD_SOURCE="http://mirror.centos"
NEW_SOURCE="http://vault.centos"

cd /etc/yum.repos.d

sudo sed -i 's/$OLD_MIRROR/$NEW_MIRROR/' CentOS-Base.repo
sudo sed -i 's/$OLD_BASEURL/$NEW_BASEURL/' CentOS-Base.repo
sudo sed -i 's/OLD_SOURCE/NEW_SOURCE/' CentOS-Base.repo

sudo yum update -y

sudo yum install epel-release -y

----------------------------

DATABASE_PASS='admin123'

## Installing mariadb
sudo yum install mariadb-server git -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

## Configuring mariadb with secure installations
### Set password for root user
sudo mysql -e "ALTER USER root@localhost IDENTIFIED BY '$DATABASE_PASS';"
### Delete anonymous users
sudo mysql -u root -p$DATABASE_PASS -e "DELETE FROM mysql.user WHERE User=''"
### Disable remote root user login
sudo mysql -u root -p$DATABASE_PASS -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
### Delete the test database
sudo mysql -u root -p$DATABASE_PASS -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
### Ensure changes take effect
sudo mysql -u root -p$DATABASE_PASS -e "FLUSH PRIVILEGES;"

## Downloading the source code and initializing the database
cd /tmp/
git clone -b main https://github.com/devbird007/Vprofile-3-tier-architecture.git

sudo mysql -u root -p"$DATABASE_PASS" -e "create database accounts"
# POSSIBLE POINT OF ERROR
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'app01' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" accounts < Vprofile-3-tier-architecture/src/main/resources/db_backup.sql
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

## Restarting mariadb-server
sudo systemctl restart mariadb

## Starting the Firewall and allowing mariadb to access from port 3306
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo systemctl restart mariadb
