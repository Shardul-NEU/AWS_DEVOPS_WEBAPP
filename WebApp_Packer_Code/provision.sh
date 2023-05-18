#!/bin/bash

#!/bin/bash

sudo yum update -y

# export DATABASEHOST=${DATABASEHOST}
# export DATABASEUSER=${DATABASEUSER}
# export DATABASEPASSWORD=${DATABASEPASSWORD}
# export DATABASE=${DATABASE}
# export PORT=${PORT}
# export DBPORT=${DBPORT}



sudo yum install -y gcc-c++ make
curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
sudo yum install -y nodejs

mkdir WebApp
unzip WebApp.zip -d WebApp

# unzip webapp.zip -d webapp
# sudo chown ec2-user:ec2-user /home/ec2-user/webapp
cd /home/ec2-user/WebApp/webapp
sudo npm install -g npm@9.6.3
sudo npm install
cd ..
sudo yum install -y amazon-cloudwatch-agent

sudo cp webapp.service ../../../etc/systemd/system/
sudo cp cloudwatch-config.json ../../../opt/

sudo systemctl daemon-reload
sudo systemctl enable webapp.service


# Install nginx
sudo amazon-linux-extras list | grep nginx
sudo amazon-linux-extras enable nginx1
sudo yum clean metadata
sudo yum -y install nginx
sudo systemctl enable nginx
sudo cp nginx.conf /etc/nginx/
sudo systemctl restart nginx
sudo systemctl reload nginx


