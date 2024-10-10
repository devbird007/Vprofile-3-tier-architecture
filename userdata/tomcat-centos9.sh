#!/bin/bash
set -uxo pipefail
TOMURL=https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz

## Install Java and its dependencies
sudo yum install java-1.8.0-openjdk.x86_64 -y
sudo yum install -y git maven wget

## Create user for Tomcat

user_exists=$(cat /etc/passwd | grep "tomcat")

if [[ -z $user_exists ]]; then
    ## User doesn't exist, create it
    sudo useradd -m --home-dir /usr/local/tomcat9 --shell /sbin/nologin tomcat
else
    ## User already exists, skip creation."
    echo "User already exists, skipping creation"
fi

## Install Tomcat
cd /tmp/
wget $TOMURL

sudo tar xvzf apache-tomcat-9.0.75.tar.gz -C /usr/local/tomcat9 --strip-components=1


## Change ownership of the files within tomcat9
sudo chown -R tomcat:tomcat /usr/local/tomcat9


## Setting up a systemd unit file
sudo rm -rf /etc/systemd/system/tomcat.service

cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target
[Service]
User=tomcat
WorkingDirectory=/usr/local/tomcat9
Environment=JRE_HOME=/usr/lib/jvm/jre
Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_HOME=/usr/local/tomcat9
Environment=CATALINE_BASE=/usr/local/tomcat9
ExecStart=/usr/local/tomcat9/bin/catalina.sh run
ExecStop=/usr/local/tomcat9/bin/shutdown.sh
SyslogIdentifier=tomcat-%i
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

# Codebuild & Deploy
git clone -b main https://github.com/devbird007/Vprofile-3-tier-architecture.git

cd Vprofile-3-tier-architecture

mvn install

sudo systemctl stop tomcat
sleep 20
rm -rf /usr/local/tomcat9/webapps/ROOT*

cp target/vprofile-v2.war /usr/local/tomcat9/webapps/ROOT.war
sudo systemctl start tomcat

sleep 20

## Configure firewall
sudo systemctl start firewalld
sudo systemctl enable firewalld
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload