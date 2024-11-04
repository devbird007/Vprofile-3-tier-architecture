#!/bin/bash

# Exit on any error
set -e

# Variables
SONAR_VERSION="10.3.0.82913"  # Update this as needed
SONAR_HOME="/opt/sonarqube"
SONAR_USER="sonar"

echo "Checking system requirements..."
# Check if system has enough memory
MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEMORY_GB=$((MEMORY_KB / 1024 / 1024))
if [ $MEMORY_GB -lt 4 ]; then
    echo "Error: SonarQube requires at least 4GB RAM. Current memory: ${MEMORY_GB}GB"
    exit 1
fi

echo "Installing prerequisites..."
# Update system and install required packages
sudo apt update
sudo apt install -y \
    openjdk-17-jdk \
    unzip \
    postgresql \
    postgresql-contrib

echo "Setting up PostgreSQL..."
# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create SonarQube database and user
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
# Download and extract SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip
sudo unzip sonarqube-${SONAR_VERSION}.zip
sudo mv sonarqube-${SONAR_VERSION} sonarqube
sudo rm sonarqube-${SONAR_VERSION}.zip

# Set ownership
sudo chown -R "$SONAR_USER:$SONAR_USER" "$SONAR_HOME"

echo "Configuring system settings..."
# Configure system limits
sudo bash -c "cat >> /etc/security/limits.conf" << EOF
sonar   -   nofile  131072
sonar   -   nproc   8192
EOF

# Configure sysctl settings
sudo bash -c "cat >> /etc/sysctl.conf" << EOF
vm.max_map_count=524288
fs.file-max=131072
EOF

# Apply sysctl settings
sudo sysctl -p

echo "Configuring SonarQube..."
# Configure SonarQube properties
sudo bash -c "cat > $SONAR_HOME/conf/sonar.properties" << EOF
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError
sonar.web.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.ce.javaOpts=-Xmx2g -Xms2g -XX:+HeapDumpOnOutOfMemoryError
sonar.path.data=/opt/sonarqube/data
sonar.path.temp=/opt/sonarqube/temp
EOF

# Create systemd service
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
LimitNOFILE=65536
LimitNPROC=4096
TimeoutStartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Setting up firewall..."
# Configure firewall
sudo ufw allow 9000/tcp
sudo ufw reload

echo "Starting SonarQube..."
# Start SonarQube service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

echo "Waiting for SonarQube to start..."
# Wait for SonarQube to start (this might take a few minutes)
while ! curl -s http://localhost:9000 > /dev/null; do
    sleep 10
    echo "Still waiting for SonarQube to start..."
done

echo "Installation complete!"
echo "SonarQube is now running on http://$(hostname -I | cut -d' ' -f1):9000"
echo "Default credentials: admin/admin"
echo "Please wait a few minutes for SonarQube to fully initialize"
echo "Don't forget to change the admin password after first login!"
------


#!/bin/bash

## This is from claude-ai
set -x

## Variables
SONAR_VERSION="10.7.0.96327"    ## Update this as needed
SONAR_HOME="/opt/sonarqube"
SONAR_USER="sonar"

## Note: Recommended RAM size for SonarQube is 4GB RAM
##       This checks the RAM size of the system
# echo "Checking system requirements..."
# MEMORY_KB=$(grep MemTotal /proc/meminfo | aws '{print $2}')
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
    unzip

## Installing postgresql
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
sudo bash -c "cat > $SONAR_HOME/conf/sonar.properties" << EOF
sonar.jdbc.username=
sonar.jdbc.password=
sonar.jdbc.url=
sonar.web.host=
sonar.web.port=

sonar.search.javaOpts=
sonar.web.javaOpts=
sonar.ce.javaOpts=
sonar.path.data=
sonar.path.temp=
EOF
## It is recommended to set the min(Xms) and max(Xmx) memory to the same value. ##

## Set "sonar.web.host127.0.0.1" if you want it only accessible on the local host.
## This is in such a case where perhaps you want sonarqube and nginx on the same server.
## And you want sonarqube only talking to Nginx. ##



# Install java-17

# Install postgresql and enable it as a system service

# Create sonar user for postgresql

# Create postgresql database for sonar user

# Connect sonar user to its database

# Install sonarqube

# Create system sonar user and attach it to sonar config directory and files

# Fill in the database user and password in the appropriate sonar properties config files

# Set up systemd service for sonar

# Modify kernel system limits for Sonar's elasticsearch

# Access sonar on port 9000