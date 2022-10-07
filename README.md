# gophish-aws-deploy
Terraform script for deploying gophish to AWS 

## Pre-Requisites
1. Must have Terraform installed
2. Must have the AWS CLI installed

## Notes
- Please, please, please change the CIDR blocks in the security groups so that the ports aren't open to the world... There are notes in the script where these variables can be changed.
- If you are feeling really fancy, there is a great oportunity to add Route53 DNS resources to this to access your instance via DNS instead of the IP.
- You will need to retreive the admin password from the ec2 instance. This step is provided in the Usage section.

## Usage
1. git clone https://github.com/secw01f/gophish-aws-deploy
2. cd gophish-aws-deploy
3. terraform init
4. terraform plan
5. terraform apply
6. ssh -i gophish-key.pem ubuntu@\<ec2 instance public dns or public IP\>
7. cat /var/log/cloud-init-output.log | grep "the password"
8. Visit https://\<ec2 instance public dns or public IP\>:3333 and log in with the admin username and password.
