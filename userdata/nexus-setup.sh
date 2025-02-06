#!/bin/bash
# This is from ClaudeAI, and it is excellent

set -x

## Variables
NEXUS_VERSION="3.73.0-12"       ## Update this as needed
NEXUS_HOME="/opt/nexus"
NEXUS_DATA="/opt/sonatype-work"
NEXUS_USER="nexus"

echo "Installing prerequisites..."
## Install java-17 and other requirements
yum update -y
yum install java-17-amazon-corretto wget -y

echo "Creating Nexus user..."
## Create the user with home directory for nexus
useradd -M -d "$NEXUS_HOME" -s /bin/bash -r "$NEXUS_USER"

echo "Downloading and installing Nexus..."
## Download nexus tar into the /opt/ directory
cd /opt/
wget "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz" -O nexus.tar.gz
tar -xvzf nexus.tar.gz
rm -f nexus.tar.gz

## Rename directories for easier management
mv "nexus-${NEXUS_VERSION}" nexus

## Set ownership
chown -R "$NEXUS_USER:$NEXUS_USER" "$NEXUS_HOME"
chown -R "$NEXUS_USER:$NEXUS_USER" "$NEXUS_DATA"

## Configuring Nexus to run as nexus user
sed -i 's/#run_as_user=""/run_as_user="nexus"/' "$NEXUS_HOME/bin/nexus.rc"

## Optional Configuring memory settings for best practices reasons
echo "-XX:MaxDirectMemorySize=2703m" >> $NEXUS_HOME/bin/nexus.vmoptions

## Create systemd service file
sudo bash -c "cat > /etc/systemd/system/nexus.service" << EOF
[Unit]
Description=Nexus Service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=$NEXUS_HOME/bin/nexus start
ExecStop=$NEXUS_HOME/bin/nexus stop
User=$NEXUS_USER
Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOF

## Enable and start Nexus service
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

echo "Waiting for Nexus to start..."
## Wait for Nexus to start (this might take a few minutes)
while ! curl -s http://localhost:8081 > /dev/null; do
    sleep 10
    echo "Still waiting for Nexus to start..."
done

echo "Getting initial admin password..."
ADMIN_PASSWORD=$(sudo cat "$NEXUS_DATA/nexus3/admin.password")
echo "Initial admin password: $ADMIN_PASSWORD"

echo "Installation complete!"
echo "Nexus is now running on http://$(hostname -I | cut -d' ' -f1):8081"
echo "Please wait a few minutes for Nexus to fully initialize"
echo "Use admin/$ADMIN_PASSWORD to log in"
echo "Don't forget to change the admin password after first login!"

# Nexus server is recommended to be 8gb ram, but 4gb ram is okay as well for smooth operations.