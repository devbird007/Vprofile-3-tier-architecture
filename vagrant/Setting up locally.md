#General Setup
For all CentOS-7 servers [db01, mc01, rmq01, app01], run the following:


## Configuring the /etc/yum.repos.d/CentOS-Base.repo file
>sudo -i
Run `vi /etc/yum.repos.d/CentOS-Base.repo`

Comment out the lines starting with **mirrorlist**, while uncommenting the
lines that start with **baseurl**.

In **baseurl**, change "http://mirror.centos..." to "http://vault.centos..."

This will occur four times for [base, updates, extras, centosplus]


## Update your server's yum repo
>yum update -y

>yum install epel-release -y


--------------------------------
#MySQL Setup:

vagrant ssh db01


## Store DB password env variable
>vi /etc/profile

Enter on the last line and close the file:
	DATABASE_PASS=admin123

>source /etc/profile


## Install Mariadb
>sudo yum install mariadb-server git -y


## Starting and Enabling mariadb-server
>sudo systemctl start mariadb

>sudo systemctl enable mariadb


## Securing the mariadb-server
>sudo mysql_secure_installation
	- Press ENTER to log in to the root with no password
	- Press Y to set root password.
	- Enter your chosen password(The one in DATABASE_PASS) and reenter it for confirmation
	- Remove Anonymous Users? Y
	- Disable remote root login? I chose Yes, even though the tutorial chose No
	- Remove Test Database? Y
	- Reload privilege tables? Y
	
## Download the Source Code & Initialize the Database
>git clone https://github.com/devbird007/Vprofile-3-tier-architecture.git
>cd Vprofile-3-tier-architecture

>mysql -u root -p"$DATABASE_PASS" -e "create database accounts"
>mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'app01' identified by 'admin123' "

>mysql -u root -p"$DATABASE_PASS" accounts < ~/Vprofile-3-tier-architecture/src/main/resources/db_backup.sql

>mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES" [THIS IS NOT NEEDED. IT'S REDUNDANT]


## Starting the Firewall and allowing mariadb to access from port no. 3306
>sudo systemctl start firewalld

>sudo systemctl enable firewalld

>sudo firewall-cmd --get-active-zones

>sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent

>sudo systemctl restart mariadb


------------------------------------------------
#MemCache Setup:
>vagrant ssh mc01

## Install memcached and dependencies
>yum install memcached -y
> yum install libmemcached -y

>systemctl start memcached
>systemctl enable memcached


## Configuring the firewall for memcache
>systemctl start firewalld
>systemctl enable firewalld

>firewall-cmd --add-port=11211/tcp
>firewall-cmd --add-port=11111/udp
>firewall-cmd --runtime-to-permanent


## Running memcached
>memcached -p 11211 -U 11111 -u memcached -d

------------------------------------------------------------
#RabbitMQ Setup
>vagrant ssh rmq01

## Install erlang [Possible Point of Error]
>wget https://packages.erlang-solutions.com/erlang/rpm/centos/7/x86_64/esl-erlang_24.0.2-1~centos~7_amd64.rpm

>yum -y install esl-erlang_24.0.2-1~centos~7_amd64.rpm

>wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.19/rabbitmq-server-3.8.19-1.el7.noarch.rpm

>yum install -y rabbitmq-server-3.8.19-1.el7.noarch.rpm

## Install dependences
>yum install -y socat logrotate

## Start and enable the service
>systemctl start rabbitmq-server
>systemctl enable rabbitmq-server

## Creating the rabbitmq configuration file
>echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

## Creating user in rabbitmq
>rabbitmqctl add_user test test

## Give the user privileges
>rabbitmqctl set_user_tags test administrator
>systemctl restart rabbitmq-server
>systemctl status rabbitmq-server

## Set firewalls for rabbitmq
>systemctl start firewalld
>systemctl enable firewalld
>firewall-cmd --zone=public --add-port=4369/tcp --add-port=5672/tcp --add-port=25672/tcp
>firewall-cmd --runtime-to-permanent 


------------------------------------------------------------
#App01 Setup
>vagrant ssh app01


## Installing Java and dependencies
>yum install java-1.8.0-openjdk.x86_64 -y
>yum install -y git maven wget

## Creating User for Tomcat
>useradd --home-dir /usr/local/tomcat9 --shell /sbin/nologin tomcat

## Installing Tomcat
>cd /tmp/
>wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz

>tar xvzf apache-tomcat-9.0.75.tar.gz -C /usr/local/tomcat9 --strip-components=1

## Change ownership of the files within tomcat9
>chown -R tomcat:tomcat /usr/local/tomcat9

## Setting up a systemd unit file
>vi /etc/systemd/system/tomcat.service

Enter the following:
```
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
```

>systemctl daemon-reload
>systemctl enable tomcat
>systemctl start tomcat

## Setting firewall]
>systemctl start firewalld
>systemctl enable firewalld
>firewall-cmd --zone=public --add-port=8080/tcp --permanent
>firewall-cmd --reload

-----------------------------------------------
#Code Build & Deploy
<<Still on app01>>

>git clone https://github.com/devbird007/Vprofile-3-tier-architecture.git

## Edit the configuration file
>vi src/main/resources/application.properties
	- Edit jdbc.password=admin123 to jdbc.password=admin123
	
## Building the artifact with maven
In the repository home, run the command:
>mvn install 

>cd target/

## Moving the war file to Tomcat webapps/ location
>cd target/
>systemctl stop tomcat
>rm -rf /usr/local/tomcat9/webapps/ROOT
>cp target/vprofile-v2.war /usr/local/tomcat9/webapps/ROOT.war
>systemctl start tomcat 



-----------------------------------------------------
#Nginx Setup
>vagrant ssh web01

## Update packages repos metadata and install nginx
>sudo -i
>apt update -y

>apt install nginx -y

##Configuring nginx
Create the file:
>vi /etc/nginx/sites-available/vproapp

Enter in the following:
```
upstream vproapp {
  server app01:8080;
}
server {
  listen 80;
  location / {
    proxy_pass http://vproapp;
  }
}
```

>unlink /etc/nginx/sites-enabled/default

>ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
>systemctl restart nginx


------------------
Login
  - username: admin_vp
  - password: admin_vp
  
Note: I can change the application by simply finding and deploying another
	  Java web app on the tomcat server
	  
	  
------------------------------------
