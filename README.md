# 3-Tier Application Setup Locally
This is a 3-tier web application set up locally with Vagrant, Virtualbox and Bash Scripting

## Architecture
![architecture](images/architecture.png)

## Prerequisites
##
- JDK 1.8 or later
- Maven 3 or later
- MySQL 5.6 or later

## Services
- Nginx --> Web Service
- Tomcat --> Application Server
- RabbitMQ --> Broker/Queuing Agent
- Memcache --> DB Caching
- ElasticSearch --> Indexing/Search Service
- MySQL --> SQL Database

## Procedure
In the `vagrant/My_Provisioning` folder, there is a **Vagrantfile** that automates the creation
and setup of 6 virtual machines in virtualbox. Execute the following command to create them:
```
cd vagrant/MY_Provisioning
vagrant up
```

# Technologies 
- Spring MVC
- Spring Security
- Spring Data JPA
- Maven
- JSP
- MySQL
# Database
Here,we used Mysql DB 
MSQL DB Installation Steps for Linux ubuntu 14.04:
- $ sudo apt-get update
- $ sudo apt-get install mysql-server

Then look for the file :
- /src/main/resources/accountsdb
- accountsdb.sql file is a mysql dump file.we have to import this dump to mysql db server
- > mysql -u <user_name> -p accounts < accountsdb.sql


