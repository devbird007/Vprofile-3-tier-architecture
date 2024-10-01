#!/bin/bash
set -euxo pipefail

#Configuring the /etc/yum.repos.d/CentOS-Base.repo file

OLD_MIRROR="mirrorlist=http"
NEW_MIRROR="#$OLD_MIRROR"
OLD_BASEURL="#baseurl=http"
NEW_BASEURL="${OLD_BASEURL:1}"
OLD_SOURCE="http://mirror.centos"
NEW_SOURCE="http://vault.centos"

cd /etc/yum.repos.d/

sudo sed -i "s/$OLD_MIRROR/$NEW_MIRROR/" CentOS-Base.repo
sudo sed -i "s/$OLD_BASEURL/$NEW_BASEURL/" CentOS-Base.repo
sudo sed -i "s#$OLD_SOURCE#$NEW_SOURCE#" CentOS-Base.repo

sudo yum update -y

sudo yum install epel-release -y