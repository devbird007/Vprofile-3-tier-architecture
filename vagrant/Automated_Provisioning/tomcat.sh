#!/bin/bash
set -euxo pipefail
TOMURL=https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz

## Install Java and its dependencies
sudo yum install java-1.8.0-openjdk.x86_64 -y
sudo yum install -y git maven wget

## Create user for Tomcat
sudo useradd --home-dir /usr/local/tomcat9 --shell /sbin/nologin tomcat

## Install Tomcat
cd /tmp/
wget $TOMURL -O tomcatbin.tar.gz

sudo tar xvzf apache-tomcat-9.0.75.tar.gz -C /usr/local/tomcat9 --strip-components=1


## Change ownership of the files within tomcat9
sudo chown -R tomcat:tomcat /usr/local/tomcat9


## Setting up a systemd unit file
sudo rm -rf /etc/systemd/system/tomcat.service

cat <<EOF>> /etc/systemd/system/tomcat.service
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

