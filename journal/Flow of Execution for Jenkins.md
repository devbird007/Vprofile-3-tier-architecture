# Jenkins

The way Jenkins works is that, when developers make their commits and push
the code to Github. Jenkins detects this and it triggers a workflow to fetch
the latest changes, run certain tests and analyses on the code, then builds and
versions the artifact from the source code. If any errors occur at any stage of 
the process, notifications will be sent through appropriate channels. When the 
process is complete, then the artifact will be deployed.


## Flow of Execution
1. Login to AWS Account
2. Create key pairs
3. Create Security Groups for Jenkins, Nexus and Sonarqube
4. Create Ec2 Instances with Userdata to set them up
5. Setup Post Installation steps. 
   - Jenkins setup and plugins
   - Nexus setup & repository setup
   - Sonarqube login test
6. Git
   - Create github repo and migrate necessary code.
   - Integrate git repository with VS Code and test it
7. Write the Jenkins Job that will build the code, this uses a Nexus integration.
8.  Create a Github Webhook to trigger the Jenkins workflow
9.  Sonarqube server integration with Jenkins
10. Nexus Artifact upload stage
11. Create Slack notification system

------
## 2. Create Key Pairs
* This is self explanatory. *

## 3. Create Security Groups for Jenkins, Nexus and Sonarqube
Navigate to **EC2>Security Groups>Create security group**

Under **Inbound rules**
- For Jenkins
  - Name: `jenkins-sg`
  - Open port `22` for ssh access
  - Open port `8080` with Source: 
    - `Anywhere-IPv4`
    - `Anywhere-IPv6`
  - Click **Create security group**

- For Nexus
  - Name: `nexus-sg`
  - Open port `22` for ssh access
  - Open port `8081` with Source: 
    - `My-IP`
    - << Your earlier created Jenkins sg >>
  - Click **Create security group**

- For Sonatype server
  - Name: `sonar-sg`
  - Open port `22` for ssh access
  - Open port `80` with Source: 
    - `My-IP`
    - << Your earlier created Jenkins sg >>
  - Click **Create security group**

- Return to the earlier created Jenkins sg and add this rule:
  - Select port `8080` with << Your earlier created Sonar sg >> as source
  
  >Note: Bear in mind, this is a redundant inbound rule since port 8080 is already open to all. It's only important in cases where access to port 8080 is restricted to your IP or specific servers.


## 4. Create Ec2 Instances for Jenkins, Nexus and Sonarqube with Userdata
Navigate to **Instances > Launch instances**

Create an Instance with the following:
- Name: `Jenkins-server`
- AMI: `Ubuntu24.04`
- Instance type: `t2.micro` 
- Key pair: Select your key pair
- Security group: Select your earlier created `jenkins-sg`
- User data: Copy the contents of `jenkins-setup.sh` into the box



# Notes
1. Please do the architecture diagrams for Jenkins in the night when sleepy. Do both diagrams.

2. Remember to edit the readme file to explain what this project is about.