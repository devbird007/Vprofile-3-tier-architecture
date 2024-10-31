# Re-architecting a Web Application for a Cloud-Native Environment

This is a distributed web application complete with a web server, 
database and along with other functionality.  
The traditional **mariadb server** is swapped out for an **AWS-managed RDS mysql service**.  
The traditional **memcached server** is swapped out for an **AWS-managed Elasticache memcached service**.  
The traditional **rabbitmq server** is swapped out for an **AWS-managed AmazonMQ rabbitmq service**.  
The traditional **tomcat servers** are swapped out for an **Amazon ElasticBeanstalk offering** that abstracts instance lifecycle, autoscaling and elastic loadbalancing.



## Architecture
![architecture](images/cloud-architecture.jpeg)

## Prerequisites
- JDK 1.8 or later
- Maven 3 or later

## Services
- Tomcat --> Application Server
- AmazonMQ(RabbitMQ) --> Broker/Queuing Agent
- Elasticache(Memcache) --> DB Caching
- RDS(MySQL) --> SQL Database
- ElasticSearch --> Indexing/Search Service

## Procedure
Upon deployment, the web application is available on `<< YOUR DOMAIN >>`, globally distributed to all AWS edge locations with Amazon CloudFront

### Setup
The setup instructions are in the **journal** directory.


## Technologies 
- Spring MVC
- Spring Security
- Spring Data JPA
- Maven
- JSP
- MySQL
  
## Database
Here, we used Mysql DB on Amazon RDS offering

Look for the file :
- /src/main/resources/db_backup.sql
- The file contains the scheme to dump into your database server.
- > mysql -u <user_name> -p accounts < db_backup.sql

## Versions
Tomcat:
  - 9.0.75 on centos9
  
Java:
  - 1.8.0 on centos9

Memcached:
  - 1.4* on Amazon ElastiCache


## Troubleshooting Common Errors
1. If your apps are deployed successfully, however you are unable to log in successfully, you could check out database connection with `telnet IP_Address PORT`
2. You should use the appropriate versions if some components aren't working such as the Memcached service