#!/bin/bash

## This is from ClaudeAI
set -x

## Variables
SONAR_VERSION="10.7.0.96327"     ## Update this as needed
SONAR_HOME="/opt/sonarqube"
SONAR_USER="sonar"

## Note: Recommended RAM size for SonarQube is 4GB RAM
##       This checks the RAM

# echo "Checking system requirements..."
# MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# MEMORY_GB=$((MEMORY_KB / 1024 / 1024))
# if [ $MEMORY_GB -lt 4 ]; then
#     echo "Error: SonarQube requires at least 4GB RAM. Current memory: ${MEMORY_GB}GB"
#     exit 1
# fi

echo "Installing prerequisites..."
## Update system and install required packages
sudo apt update
sudo apt install -y \
    openjdk-17-jdk \
    unzip \
    postgresql \
    postgresql-contrib

echo "Setting up PostgreSQL..."
## Start Postgresql service
sudo systemctl start postgresql
sudo systemctl enable postgresql

## Create SonarQube database and user
sudo -u postgres psql << EOF
CREATE USER sonar WITH ENCRYPTED PASSWORD 'sonar';
CREATE DATABASE sonarqube OWNER sonar;
ALTER USER sonar WITH SUPERUSER;
\q
EOF

echo "Creating SonarQube user..."
# Create sonar user
sudo useradd -M -d "$SONAR_HOME" -s /bin/bash -r "$SONAR_USER"

echo "Downloading and installing SonarQube..."
## Download and extract SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip
sudo unzip sonarqube-${SONAR_VERSION}.zip
sudo mv sonarqube-${SONAR_VERSION} sonarqube
sudo rm sonarqube-${SONAR_VERSION}.zip

## Set ownership
sudo chown -R "$SONAR_USER:$SONAR_USER" "$SONAR_HOME"

echo "Configuring system settings..."
## Configure system limits
sudo bash -c "cat >> /etc/security/limits.conf" << EOF
sonar   -   nofile  131072
sonar   -   nproc   8192
EOF

## Configure sysctl settings
sudo bash -c "cat >> /etc/sysctl.conf" << EOF
vm.max_map_count=524288
fs.file-max=131072
EOF

## Apply sysctl settings
sudo sysctl -p

echo "Configuring SonarQube..."
## Configure SonarQube properties
sudo bash -c "cat >> $SONAR_HOME/conf/sonar.properties" << EOF
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=127.0.0.1:9000
sonar.web.port=9000


sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError
# sonar.web.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
# sonar.ce.javaOpts=-Xmx2g -Xms2g -XX:+HeapDumpOnOutOfMemoryError
sonar.path.data=/opt/sonarqube/data
sonar.path.temp=/opt/sonarqube/temp
EOF

## Note: It is recommended to set the min(Xms) and max(Xmx) memory to
##       the same value.

##       Set "sonar.web.host=127.0.0.1" in scenarios where you want it only
##       speaking to a web server like Nginx, otherwise leave it at 0.0.0.0

## Create systemd service
sudo bash -c "cat > /etc/systemd/system/sonarqube.service" << EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target postgresql.service

[Service]
Type=simple
User=$SONAR_USER
Group=$SONAR_USER
PermissionsStartOnly=true
ExecStart=$SONAR_HOME/bin/linux-x86-64/sonar.sh console
StandardOutput=syslog
LimitNOFILE=131072
LimitNPROC=8192
TimeoutStartSec=5
Restart=always
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF

echo "Starting SonarQube..."
## Start SonarQube service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

echo "Waiting for SonarQube to start..."
## Waiting for SonarQube to start (this might take a few minutes)
while ! curl -s http://localhost:9000 > /dev/null; do
    sleep 10
    echo "Still waiting for SonarQube to start..."
done

echo "Installation complete!"
echo "SonarQube is now running on http://$(hostname -I | cut -d' ' -f1):9000"
echo "Default credentials: admin/admin"
echo "Please wait a few minutes for SonarQube to fully initialize"
echo "Don't forget to change the admin password after first login!"


## Install Nginx web server
### Install nginx
sudo apt install nginx -y

### Configure nginx web server file
sudo rm -rf /etc/nginx/sites-enabled/default

sudo bash -c "cat > /etc/nginx/sites-enabled/sonarqube" << EOF
server {
    listen 80 default_server;
    server_name sonarqube.example.com;

    access_log /var/log/nginx/sonarqube.access.log;
    error_log /var/log/nginx/sonarqube.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }
}
EOF

sudo nginx -t

sudo systemctl restart nginx

## Minimum requirement is a t2.medium server