#!/bin/bash
set -x
TOMURL=https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.31/bin/apache-tomcat-10.1.31.tar.gz

sudo apt update -y

## Install java and its dependencies
sudo apt install default-jdk -y
java -version

sudo apt install git maven wget -y



## Create user with home directory for Tomcat
user_exists=$(cat /etc/passwd | grep "tomcat")

if [[ -z $user_exists ]]; then
    ## User doesn't exist, create it
    sudo useradd -m --home-dir /opt/tomcat --shell /sbin/nologin tomcat
else
    ## User already exists, skip creation."
    echo "User already exists, skipping creation"
fi

## Install tomcat
cd /tmp/

if [ -f "/tmp/apache-tomcat*" ]; then
    echo "Tomcat already exists. Skipping download."
else
    echo "Downloading tomcat..."
    wget $TOMURL
    sudo tar -xzvf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
fi


## Change ownership of the files within tomcat9
sudo chown -R tomcat:tomcat /opt/tomcat
sudo chmod -R u+x /opt/tomcat/bin

## Make some configs in the tomcat users file
sudo cat <<EOF >> /opt/tomcat/conf/tomcat-users.xml
<role rolename="manager-gui" />
<user username="manager" password="password" roles="manager-gui" />

<role rolename="admin-gui" />
<user username="admin" password="password" roles="manager-gui,admin-gui" />
EOF

## Edit files for permissions for manager and host-manager above
manager_path="/opt/tomcat/webapps/manager/META-INF/context.xml"
host_manager_path="/opt/tomcat/webapps/host-manager/META-INF/context.xml"

paths=("$manager_path" "$host_manager_path")

# Perform sed operations to comment out the required lines in place
for path in "${paths[@]}"; do

    # Implement idempotency for the `sed` operation
    search_string="<!-- <Valve className"
    if grep -q "$search_string" "$path"; then
	    echo "Search string found, skipping "sed" sequence..."
    else
	    echo "Performing sequence"
        sed -i 's/<Valve className=/<!-- <Valve className=/' $path  #comments out the start of line one
        sed -i 's#0:0:1\" />#0:0:1\" /> -->#' $path                 # comments out the end of line two
    fi
done


## Setting up a systemd unit file
sudo rm -rf /etc/systemd/system/tomcat.service

cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-1.21.0-openjdk-amd64/"

Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat