#!/bin/bash

## This is a fairly standard installation bash script I got from the web. I should base my own installations off of it ngl
set -x

## Change this to java 17
yum install java-1.8.0-openjdk.x86_64 wget -y

## Create the user with home directory for nexus
useradd -m -U -d /opt/nexus nexus

## Download nexus tar in the tmp directory
cd /tmp/

## For Latest: NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"

NEXUSURL="https://download.sonatype.com/nexus/3/nexus-3.73.0-12-unix.tar.gz"
wget $NEXUSURL -O nexus.tar.gz

sleep 10
tar xvzf nexus.tar.gz -C /opt/nexus/ --strip-components=1

sleep 5
rm -f /tmp/nexus.tar.gz

sleep 5
chown -R nexus.nexus /opt/nexus

## Create systemd unit file for Nexus so it can run on startup
cat <<EOT>> /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc
systemctl daemon-reload

systemctl start nexus
systemctl enable nexus
