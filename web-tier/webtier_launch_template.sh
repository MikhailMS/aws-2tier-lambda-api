#!/bin/bash
sudo yum -y install docker aws-cfn-bootstrap
sudo service docker start

aws ecr get-login-password --region ${image_region} | sudo docker login -u AWS --password-stdin ${ecr_account_id}.dkr.ecr.${image_region}.amazonaws.com/${image_repository}
sudo docker run -d -p 80:5000 --name="web-tier" -h ${webtier_dns_name} ${ecr_account_id}.dkr.ecr.${image_region}.amazonaws.com/${image_repository}:${image_tag}
