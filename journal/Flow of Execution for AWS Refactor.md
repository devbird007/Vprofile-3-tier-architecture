# Flow of Execution for AWS Refactor
1. Create Key Pair for Beanstalk Instance login
2. Create Security Group for ElastiCache, RDS & Active MQ
3. Create RDS, Amazon ElastiCache(memcached), Amazon MQ(rabbitmq)
4. Launch EC2 and Initialize the RDS DB
5. Create Elastic Beanstalk Environment
6. Update SG of backend to allow traffic from Bean SG
7. Edit Elastic Beanstalk LoadBalancer Configs
8.  Build Artifact with Backend Information
9.  Deploy Artifact to Beanstalk
10. Create CloudFront CDN with SSL Certificate
11. Update Load-balancer endpoint in GoDaddy DNS Zones or Route53 Public DNS Zone
12. Test everything from the URL

---

# Edits to Make Later
At the end of this project, I am going to redo it and rewrite this page according to the improvements. Specifically these following steps:

1. Create RDS, Amazon ElastiCache(memcached), Amazon MQ(rabbitmq)
2. Create Elastic Beanstalk Environment
3. Update SG of backend to allow traffic from Bean SG
4. Launch one of the EBS-created EC2 instances for DB initializing
5. Carry out the initializing, and then delete the repo when completed
6. Edit Elastic Beanstalk LoadBalancer Configs
7.  Build Artifact with Backend Information
10. Deploy Artifact to Beanstalk
11. Create CDN with SSL Cert.

>Note: I will also skip over Step-3, to check if it is redundant. Because note that the backend services sg already allow all traffic internally, and the EBS-created instances are attached to that sg. So technically, there shouldn't be a need to update their rules to accept traffic on ports from the EBS-created sg

---

## 1. Create Key Pair for Beanstalk Instance Login
* This is self explanatory *

## 2. Create Security Group for the Backend Services
Navigate to **EC2>Security Groups>Create security group**

Under **Name**, enter a name such as `myprofile-backend-sg`

Under **Inbound rules**
- Create a dummy rule such as an ssh rule from my IP, even though it will be impossible to connect to the services publicly since they will be contained in a private network, then click **Create security group**.
- Upon successful creation, edit the sg to include a rule to allow `All traffic` from the SG's own `id`. This facilitates communication on all ports between the servers with this sg.

## 3. Create Amazon RDS, ElastiCache and Active MQ
### Create the MySQL Database with Amazon RDS
Create the Subnet Group
- Navigate to **RDS>Subnet groups>Create DB subnet group**
- Under **Name**, enter a name such as `myprofile-rds-sub-group`
- Select any number of **Availability Zones**(6) and **Subnets**(6) 
- Click **Create**

Create the Parameter Group
- Under **Parameter group name**, enter a name such as `myprofile-rds-para-group`
- Under **Engine type**, select **MySQL Community**
- Under **Parameter group family**, select **MySQL 8\***
- Click **Create**

Now Create the Database
- Click your way to **Databases>Create database**

- Under **Choose a database creation method**, select **Standard create**

- Under **Engine options**
  - Under **Engine type**, select **MySQL**
  - Under **Engine version**, select **MySQL 5.7\***, or choose **MySQL 8\*** to not have to pay for Extended Support

- Under **Templates**, chose **Dev/Test**

  >Note: The difference between "Production" and "Dev/Test" is that Prod. gives you multiple AZ configurations for High Availability, along with High IOPs(throughput volume)

- Under **Availability and durability**, leave **Single DB instance** as is unless in a production setup environment

- Under **Settings**
  - Set **DB instance identifier** to a name you choose

  - Under **Credentials management**, select **Self managed** and click the checkbox for **Auto generate password**

- Under **DB instance class**, choose a **Burstable classes** equivalent of regular EC2 instances such as `db.t3.micro`

  >Note: r series and x series are considered really good for databases, t series are low-cost, and they are what we will be using here.

- Under **Storage**
  - Under **Storage type**, select **gp2** for free tier purposes

    >Note: **Provisioned IOPs** is better for when there's too much workload, too much throughput to be expected

  - Under **Allocated storage**, enter `20`

  - Under **Storage autoscaling**, leave as enabled and max at 1000

- Under **Connectivity**
  - Under **DB subnet group** choose the earlier created subnet group, likely leave the options before this as is.
  - Under **VPC security group**, choose te earlier created backend sg

- Under **Database authentication**, leave **Password auth...** as is

- Under **Monitoring**, disable for costs

- Under **Additional configuration**
  - Under **Database options**
    - Under **Initial database name**, enter an appropriate name such as **accounts**
    - Under **DB parameter group**, select your earlier created parameter group
  - Under **Backup**
    - You may leave as Enabled
    - You may increase **Backup retention period** to max 35days or leave as 7
  - Under **Log exports**, select all four to export to CloudWatch
  - Under **Maintenance**, Check **Enable auto minor version upgrade**
  - Under **Deletion protection**, Check the box

- Click **Create Database** at the bottom

### Create Amazon ElastiCache
Create the Parameter Group
- Navigate to **Amazon ElastiCache>Configurations>Parameter groups>Create parameter group**
- Under **Name**, enter a name such as `vprofile-memcached-para-grp`
- Under **Family**, select **memcached1.4**
- Click **Create**

Create Subnet groups
- Click **Create subnet group**
- Under **Name**, enter a name such as `vprofile-memcached-sub-grp`
- Leave the default VPC, and the default selected subnets(6)
- Click **Create**

Now Create the Memcached Service
- Click your way to **Resources>Memcached caches>Create Memcached cache**

- Under **Choose a cluster creation method**
  - Under **Deployment option**, select **Design your own cache** and **Standard create**
- Under **Location**, choose **AWS Cloud**
- Under **Cluster info**, enter an appropriate name like `vprofile-elasticache-svc`
- Under **Cluster settings**
  - Under **Engine version**, select `1.4.5`
  - Under **Parameter groups**, select your earlier created parameter group
  - Under **Node type**, select `cache.t3.micro`
- Under **Subnet group settings**, choose your earlier created subnet group

- Under **Selected security groups**, click **Manage** and then select your earlier created sg
- Under **Maintenance**
  - Leave **Maintenance window** as **No preference**
  - Leave SNS Topic as Disabled if you want

- Review all the settings on the final page, then click **Create**

### Create Amazon MQ
Navigate to **Amazon MQ>Brokers>Create brokers**

Under **Broker engine types**, select **RabbitMQ**

Under **Deployment mode**, select **Single-instance broker**

Under **Broker name**, enter a name such as `myprofile-rmq`

Under **Broker instance type**, choose the type `mq.t3.micro`

Under **RabbitMQ access**, enter a random username and password you'll remember

Under **Broker engine version**, select probably the lowest version

Under **Broker configuration**, leave as **Create a new one with configuration defaults**

Under **Access type**, select **Private access**

Under **Security group(s)**, select your earlier created backend sg

Under **Encryption**, leave default

Under **Tags**, enter `Name:myprofile-rmq01`

Review all the settings on the final page, then click **Create**


## 4. Launch EC2 and Initialize the RDS DB
### DB Initialization
Copy your `username`, `password` and `endpoint` that will be generated upon successful creation of your database

Create an EC2 Instance simply to initialize the DB
- Navigate to **EC2>Instances>Launch an instance>>**
  - Instance Name: `mysql-client`
  - OS: `ubuntu22.04`
  - Create a sg
    - Name: `mysqlClient-sg`
    - Inbound Rules: ssh login
  - Add the following to the User data:
    ```
    #!/bin/bash
    set -x

    sudo apt update
    sudo apt install -y mysql-client
    ```

Edit the sg for backend servers to accept traffic of type `MySQL` on port `3306` from the sg of the newly created instance

`ssh` into your newly created instance

Clone the repository to get the database schema:
```
git clone -b aws-refactor https://github.com/devbird007/Vprofile-3-tier-architecture.git
```

Fill the `accounts` database with the schema with the following command:
```
mysql -h vprofile-rds-mysql.c7my2q6maqh6.us-east-1.rds.amazonaws.com -u admin -pIeLchWH51VqpBYQsUVzB accounts < Vprofile-3-tier-architecture/src/main/resources/db_backup.sql
```

Run the following command to access the `accounts` database in RDS mysql:
```
mysql -h <<Database endpoint from earlier>> -u <<username>> -p<<password>> accounts
```


## 5. Create Elastic Beanstalk Environment
### Note down the required endpoints
Note down the `db-username`, `db-password`, `db-endpoint`

Note down the `rmq-username`, `rmq-password` and endpoint that is specifically the string inbetween `amqps://<<HERE>>:5671`

Note down the endpoint of the available node in the Elasticache service, which is everything except the port and the colon in front of it, like so `<<Actual Endpoint>>:<<PORT>>`

### Create the Elastic Beanstalk Application
Navigate to **Elastic Beanstalk>Create application**

Enter an appropriate name such as `myprofile-java-app`

Enter the tag: `Project=Myprofile`

Click **Create**

>Note: You only need this suceeding subsection if you have never created a role for your ElasticBeanstalk instances
### Create the Role for Elastic Beanstalk
Navigate to **IAM>Roles>Create role**

Under **Trusted entity type**, choose **AWS service**

Under **Use case**, select **EC2**

Under **Permissions policies**, select the following policies:
- AWSElasticBeanstalkWebTier
- AWSElasticBeanstalkWorkerTier
- AWSElasticBeanstalkMulticontainerDocker

Enter this specific name for the role: `aws-elasticbeanstalk-ec2-role`

Click **Create role**

### Create the Environment for the Elastic Beanstalk Application
Click your way to **Elastic Beanstalk>/<< Your newly created application >>/> Create environment**

Under **Environment tier**, select **Web server environment**
Under **Tags**, enter `Project=Myprofile`

Under **Environment information**, leave as is

Under **Platform**
- Under **Platform type**, leave as **Managed platform**

- Under **Platform**, select **Tomcat**

- Under **Platform branch**, select **Tomcat 9 with Corretto 11...**
  >Note: The java type used in Elastic Beanstalk environment isn't openjdk but rather corretto

Under **Application code**, leave as **Sample application**

Under **Presets**, select **Custom configuration**

Under **Service access**
- Under **Service role**, select `aws-elasticbeanstalk-service-role` or  **Create and use new service role**
- Under **EC2 key pair**, choose your key pair
- Under **EC2 instance profile**, if you don't already have any, select the earlier created instance role `aws-elasticbeanstalk-ec2-role`

Under **VPC**, select your VPC

Under **Instance settings**
- Under **Public IP address** set to  `Activated`
- Under **Instance subnets**, select all

Under **Database**, ignore all for now *---Note that this is outdated setup*
>Note: For production purposes, you should not mention your RDS database and get it tied up with your Beanstalk instances, your database should have its own rds instance. If you delete Beanstalk, you don't want your database to get deleted.

Under **Root volume**, select **General Purpose (SSD)**

Under **EC2 security groups**, select your earlier created backend sg

Under **Auto scaling group**
- Under **Environment type**, select **Load balanced**
- Under **Instances**: `min=2` and `max=8`
- Under **Fleet composition**, leave as default or change according to your need
- Under **Instance types**, select `t2.micro`
- Under **Placement**, select all the availability zones
Under **Scaling triggers**
- Under **Metric**, select `NetworkOut` as it is very popular for web applications
- Leave the rest at default

Leave Load Balancer settings as default for now

Under **Monitoring**, leave as is at **Enhanced**

Under **Managed platform updates**, I'd rather leave as `deactivated`

Under **Application deployments**
- Under **Deployment policy**, select **Rolling**
- Under **Batch size type**, set to `50%` for the two instances we have
- Leave the rest as is

Review and then click **Submit** on the final page


## 6. Update SG of backend to allow traffic from Bean SG

Navigate to **EC2>Security Groups><</ Your earlier created backend sg />>**

Under **Edit inbound rules**
*<- For MY_PORT in [3306, 11211, 5671], do:*
- Add a rule of **Port range** << MY_PORT >>, **Source** << sg created by Elastic Beanstalk for the EC2 instances >>
*done ->
>Note: Instead of 3 rules, you could create 1 rule to allow all traffic from the << sg created by Elastic Beanstalk for the EC2 instances >>. However this is less optimal from a security standpoint.


## 7. Edit Elastic Beanstalk LoadBalancer Configs
Navigate to **Elastic Beanstalk><</ Your created environment />>Configuration>Instance traffic and scaling**

### Add 443 HTTPS Listener to ELB
Scroll down to **Listeners** and click **Add listener**
- Under **Listener port**, type in `443`
- Under **Listener protocol, select **HTTPS**
- Under **SSL certificate**, select your cert
- Click **Save**

###  Change healthcheck on beanstalk to /login
Scroll to **Processes**. Edit the **default** process
- Under **Health check**
  - Under **Path**, change it to `/login`
- Under **Sessions**
  - Enable Session stickiness
- Click **save**


## 8.  Build Artifact with Backend Information
Go to your local directory where this repo is cloned

Edit the `src/main/resources/application.properties` file:
- For mysql
  - For `jdbc.url`: Change `...mysql://<< HERE >>:3306/accounts?...` to << Earlier saved mysql RDS endpoint >>
  - For `jdbc.username`: << Your earlier saved mqsql username >> (or the default `admin`)
  - For `jdbc.password`: << Your earlier saved mqsql password >>
- For memcached
  - For `memcached.active.host`: << Your earlier saved Elasticache endpoint >> MINUS the port-number attached to it. 
- For rabbitmq
  - For `rabbitmq.address`: << Your earlier saved rabbitmq endpoint >>, also minux the port number attached with the colon
  - For `rabbitmq.port`: Ensure the port in the file is the same as the one attached to the aws rabbitmq endpoint
  - For `rabbitmq.username`: << Your earlier saved rabbitmq username >>
  - For `rabbitmq.password`: << Your earlier saved rabbitmq password >>

Return to the base of the directory and run `mvn install`


## 9.  Deploy Artifact to Beanstalk
Navigate to **Elastic Beanstalk><</ Your created environment />>Upload and deploy**

Select the file located in `REPO_DIRECTORY/target/vprofile-v2.war`

Give a version label if you desire

Change Health threshold to **Severe** --if needed--, and change back after successful deployment
Click **Deploy**

### Connection to DNS
Go to where your domain name is registered, e.g **godaddy**

Add a DNS record of `type=CNAME`, `Name=myprofile`, `Value=<< Your Elastic Beanstalk Endpoint >>`


## 10. Create CloudFront CDN with SSL Certificate
Navigate to **CloudFront>Create a CloudFront distribution**

Under **Origin**
- Under **Origin domain**, enter the subdomain you created earlier `myprofile.*`
  >Note: You can also just link the domain name directly
- Under **Protocol**, change to **Match viewer**
- Under **Minimum Origin SSL protocol**, select `TLSv1`

Under **Default cache behavior**
- Under **Viewer**
  - Under **Allowed HTTP methods**, leave as selected all

Under **Settings**
- Under **Price class**, leave as **Use all edge locations...**
- Under **Alternate domain name...**, enter your subdomain: `myprofile.*`

Under **Custom SSL certificate**, select your cert
- Under **Security policy**, select `TLSv1`
  >Note: you can switch between `TLSv1` and the latest should you encounter errors with your CloudFront

Click **Create distribution**





