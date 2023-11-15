#!/bin/bash
sudo yum -y install docker aws-cfn-bootstrap
sudo service docker start

sudo docker run -d -p 80:5000 --name="web-tier" -h ${webtier_dns_name} ${ecr_account_id}.dkr.ecr.${image_region}.amazonaws.com/${image_repository}:${image_tag}
