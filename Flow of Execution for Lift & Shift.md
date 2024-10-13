# Flow Of Execution For Lift & Shift
1. Login to AWS Account
2. Create Security Groups for all groups of instances
3. Create Key Pairs
4. Launch Instances with userdata[Bash Scripts]
5. Update IP to name mapping in Route53
6. Build Application from source code
7. Upload the built artifact to S3
8. Download the artifact to Tomcat Ec2 instance
9. Buy a Domain and Configure SSL Certificate for your Domain
10. Setup ELB with HTTPS [Certs from AWS Certificate Manager]
11. Map ELB Endpoint to website name in Godaddy DNS
12. Verify that the entire setup works
13. Build Autoscaling Group for the Tomcat Instances to handle load

-----------------------------------

## 2. Create your Security Groups
Navigate to **AWS Security Groups**
   
### Create a sg for your Elastic Load Balancer
- Configure the Inbound Rules. 4 total:  
	1. HTTP: Anywhere(IPv4) & (IPv6)  
	2. HTTPS: Anywhere(IPv4) & (IPv6)   
- Leave the Outbound Rules, only configure them in a real-world production setup.

### Create a sg for your Tomcat instances
- Configure the Inbound Rule 
	1. **Port**=8080, **Source**=[sg for earlier created ELB], **Description**="Allow traffic from ELB sg"
	2. **Type**=SSH, **Source**=`My IP`
	
### Create a sg for the backend services[rabbitmq, memcached, mysql]
- Configure the Inbound Rules
  1. **Type**=Mysql/Aurora, **Port**=3306, **Source**=[sg for earlier created app], **Description**="Allow connection from app servers to mysql"
	2. **Port**=11211, **Source**=[sg for earlier created app], **Description**="Allow connection from app servers to memcached"
	3. **Port**=5672, **Source**=[sg for earlier created app], **Description**="Allow connection from app servers to rabbitmq"  
		` Create the Security Group`
	4. **Type**=All Traffic, **Source**=[select its own sg], **Description**="Allow internal traffic to flow on all ports for the services in the backend"
	5. **Type**=SSH, **Source**=`My IP`


>Note: The `application.properties` file from the Java source code will contain 
the necessary ports for the backend services, you can always check it out.


## 3. Create Key Pairs
Navigate to **Key Pairs**

Select **Create key pair**

Enter an appropriate name

Leave the rest as defaults (RSA, .pem)

Click **Create key pair** at the bottom 


## 4. Launch Instances with Userdata

### Create Backend Servers
*<- For SERVICE in [db01, mc01, rmq01], do:*

  - Navigate to **Launch Instances**
  - Name the instance: "vprofile-<< SERVICE >>"
  - Click **Add Tag**:
    - **Key**   =  "Project"
    - **Value** = "vprofile"
  - Select **CentOS-9** image
  - Under **Key Pair**, select your earlier created keys.
  - Under **Security Group**, select the earlier created backend sg.
  - Expand **Advanced Options** and scroll to **User data** at the bottom
  - Copy the contents of `userdata/<< SERVICE >>` into the box.
  - Click **Launch Instance**

*done ->*

### Create Tomcat Server
Import << Create Backend Servers >>, but change the following:
  - Name the instance: "vprofile-app01"
  - Select **Ubuntu-24.04** Image
  - Under **Security Group**, select the earlier created tomcat sg.
  - For **User data**, copy the contents of `userdata/tomcat*`


## 5. Update the Private IP of the 3 Backend instances in Route53 private DNS zones
*Note down the Private IPs of the three instances*
  
### Create a Private Hosted Zone
  - Navigate to **AWS Route53**
  - Click your way to **Create hosted zones**
  - Give any domain name, such as `vprofile.in`
  - Under **Type**, select **Private Hosted Zone**
  - Select the appropriate **Region** & **VPC ID** for the vpc you will be working in. Typically in `us-east-1`.
 
### Create Records for the Backend Servers
*<-For SERVICE in [db01, mc01, rmq01], do:*
   - Click **Create record**
   - Under **Choose routing policy**, select **Simple routing**
   - Under **Configure records**, select **Define simple record**  
     - Under **Record name**, enter << SERVICE >>
     - Under **Value/Route traffic to**, select **IP Address or another value...**. Then type in the Private-IP for << SERVICE >>
     - Under **Record type**, leave **A - Routes traffic...**
     - Click **Define simple record**

*done*
   - Click **Create records**


## 6. Build Application From Source Code
Install mvn and the appropriate java version on your local computer.

Run `cd` to the project's directory, since you should've cloned it by now.

Edit the file at `src/main/resources/application.properties`:
- Edit where [db01, mc01, rmq01] appear to [db01.vprofile.in, mc01.vprofile.in, rmq01.vprofile.in]. This is to match their record names as created earlier.
 - If you've edited other things in the userdata scripts, you should also edit them in this file too so they match.

Go to the top level of the directory and run `mvn install`


## 7. Upload the built artifact to S3
Create a user, give them programmatic access, give them only "Full access to S3", download their access and secret keys.

Set up your aws-cli with `aws configure` to attach the keys for the newly created user to your terminal environment.

Create an s3 bucket in the cli with the following command:
```
aws s3api create-bucket \
  --bucket << my bucket name >> \
  --region us-east-1
```

Run `cd` to the **target** directory inside the project directory.

Copy the artifact `vprofile-v2.war` to the newly created s3 bucket with the command:
```
aws s3api put-object \
  --bucket << my bucket name >> \
  --key vprofile-v2.war \
  --body vprofile-v2.war
```

## 8. Download the artifact to Tomcat Ec2 instance
In order to download the artifact to Tomcat Ec2 instances, create a role
### Creating A Role
Click **Create role** in the IAM section

Under **Select trusted entity**
  - Under **Trusted entity type**,  leave as **AWS service**
  - Under **Use case**, select **EC2**
    - Leave as default selection of **EC2** too
Under **Add Permissions**
  - Under **Permissions policies**, choose **AmazonS3FullAccess**
Under **Name, review, and create**
  - Under **Role name**, enter "<< my bucket name >>-role"
  - Scroll down and click **Create role**

### Attach EC2 Instance to the role
Click your way to **Instances>/<< TOMCAT INSTANCE >>/>Actions>Security>Modify IAM role**

Select your newly created role

### Downloading the artifact
Log in to your tomcat instance

Stop the tomcat service with `systemctl stop tomcat` as root

Delete the `/opt/tomcat/webapps/ROOT` directory

Install aws-cli with the following commands in `/tmp`:
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
```

Run the following command to download the artifact from the s3 bucket:
```
aws s3api get-object \
--bucket << my bucket name >> \ 
--key s3/path/to/my/artifact  ((In this case that's just plain old vprofile-v2.war)) \
/path/to/the/destination/file ((In this case you could just save it as `vprofile-v2.war`))
```

Copy the destination file to a file named `/opt/tomcat/webapps/ROOT.war`

Start up the tomcat service.

>Note: To see `application.properties` in the tomcat server, open the file at `/opt/tomcat/webapps/ROOT/WEB-INF/classes/application.properties`

#### Troubleshooting with telnet
`telnet` is useful during troubleshooting. You can use it to test network connectivy between your servers. For example on the tomcat 
server, you can run `telnet db01.vprofile.in 3306` to verify the 
connectivity between the tomcat and mariadb instances.

You have to pay attention to the host names and IP addresses that
your tomcat is using to connect to the backend services.

## 9. Buy a Domain and Configure SSL Certificate for your Domain
Purchase a domain of your choice from Godaddy

### Creating a Free SSL 
Click **Request a certificate** at the AWS ACM page

Under **Certificate Type**, select **Request a public...**

Under **Enter a Fully qualified domain name**, type in `*.<< your domain >>`

Under **Validation method**, leave **DNS Validation**

Under **Tags**, create a new tag like so: Name=<< your domain >>

Click **Request** to finalize the process.

### Attaching the SSL Certificate to your GoDaddy domain
Click **Certificate ID** to open the newly created cert

Scroll to **Domains** and take note of **CNAME name** and **CNAME value**

Go to **My Products** on GoDaddy

Click **DNS** on your newly created domain.

Click **Add new record**

Enter in type **CNAME** and input the appropriate `name` and `value` that you took note of above. Remove the period(.) at the end of both.

Click **Save** on the popup that comes up next.

Back on the AWS ACM Certificates page, the status of the newly created certificate should switch to "Issued".

>Note: If it isn't showing "Issued" a short while after completing the above step, you should delete the certificate, and repeat the request process to get a new one.

## 10. Setup the Elastic Load Balancer
You need to first create a target group
### Create a Target Group
Navigate to **EC2 Instances>>Load Balancing>>Target Groups** and click **Create target group**

Under **Specify group details**
- Under **Basic configuration**
  - Under **Choose a target type**, select **Instances**
  - Under **Target group name**, enter a name such as `vprofile-app-TG`
  - Under **Protocol : Port**, choose **HTTP : 8080** since Tomcat is serving on `8080`
- Under **Health checks**
  - Under **Health check path**, type in **/login**
- Under **Advanced health check settings**
  - Under **Health check port**, select **Override**, enter port `8080`

Under **Register targets**
- Select your tomcat instance
- Click **Include as pending below**

Click **Create target group**

### Create the Load Balancer
Click **Create load balancer** and select **Application Load Balancer**

Under **Basic Configuration**, enter an appropriate name like `vprofile-prod-elb`

- Under **Scheme**, select **Internet facing**

- Select **IPv4**

Under **Network mapping**
- Select at least two availability zones

- Select only the earlier created sg for ELB

Under **Listeners and routing**
- For **Listeners**: Add another listener for HTTPS, and select the earlier created target group for both of them.

- Under **Certificate (from ACM)**, select your earlier created ACM certificate

Scroll to the bottom and click **Create load balancer**

## 11. Map ELB Endpoint to website name in Godaddy DNS

Copy the **DNS name** for the newly created loadbalancer

Go to GoDaddy and create a new CNAME record with the details:
- Type: CNAME
- Name: vprofileapp
- Value: << your DNS name >>
Click **Save**


## 12. Verify that the entire setup works
Open a browser and type in: `https://vprofileapp.<< your domain name >>`

Log in with admin_vp // admin_vp

Successful login proves that the database is fine

Click around to test rabbitmq and memcached functionality


## 13. Build Autoscaling Group for the Tomcat Instances

### Create an AMI Image of your Tomcat server
Click your way to **Instances>/<< TOMCAT INSTANCE >>/>Actions>Image and Templates>Create image**

Under **Image name**, enter a name like `vprofile-app-image`

Click **Create image**

### Create a Launch Template for the Auto-Scaling Group
Click your way to **Instances/Launch Templates/ Create launch template**

Under **Launch template name**, enter a name like `vprofile-app-LT`

Under **Auto Scaling guidance**, click the checkbox

Under **Application and OS Images**, click your earlier created AMI image

Under **Instance type**, click type `t2.micro`

Under **Key pair**, select your key

Under **Subnet**, leave as is

Under **Security groups**, select the appropriate sg for tomcat instances

Under **Advanced details**
- Under **IAM Instance profile**, select your earlier created IAM role to facilitate working with s3 buckets
- Under **Detailed CloudWatch monitoring**, select **Enable**

Click **Create launch template** at the bottom

### Create the Auto-Scaling Group
Clcik your way to **Auto Scaling Groups>Create Auto Scaling group**

Under **Choose launch template**
- Under **Name**, enter an appropriate name like, vprofile-app-ASG
- Under **Launch template**, enter your earlier created LT

Under **Choose instance launch options**
- Under **Availability Zones and subnets**, select all or according to your requirements

Under **Configure advanced options**
- Under **Load balancing**, select **Attach to an existing load balancer**, then select your earlier created target-group
- Under **Health checks**, click **Turn on Elastic Load Balancing health checks**

Under **Configure group size and scaling**
- Under **Desired capacity**, enter your choice(2)
- Adjust **Scaling limits** according to your taste(min=1, max=2)
- Select **Target tracking scaling policy**
  - Leave all the present values as is

Under **Add notifications**, you may configure an SNS Topic to send notifications about the Auto-Scaling Group operations

Under **Tags**, you may define a tag such as `Name=vprofile-app` and `Project=vprofile` or `Owner=<< Your team name`

Verify your options and finally click **Create Auto Scaling group**


>Note: You can attach your backend servers to your newly created Auto Scaling group by clicking your way to **Instances><</ Your backend server />>>Actions>Instance Settings>Attach to Auto Scaling Group**