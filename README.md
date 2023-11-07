# AWS 2 Tier application with API Gateway

Attempt to build 2 Tier application that utilises API Gateway

Simple representation of the thing that gets built with this Terraform project:
```
                   -------------------------------------------------------------
                   |                          MAIN VPC                         |
                   |                                                           |
                   |                                        <-->   Auth Lambda |
              -----------                                   |                  |
Client --->   | Route 53 | -> | --> Web GUI --> API Gateway  -->   Lambda 1    |
              ------------                                  |                  |
                   |                                        -->    Lambda 2    |
                   |                                                           |
                   |                                                           |
                   -------------------------------------------------------------
```

Auth(authentication) Lambda is required so we can delegate authentication to API Gateway (albeit there are other ways to do this) instead of doing it in Lambda 1/2


## Usage
1. Git clone this project
2. Ensure you have authentication credentials set for Terraform; account should have permissions to create:
    1. Networks: VPC, Subnets, LB etc
    2. Applications: Auto Scaling groups, Launch templates etc
    3. API Gateway
    4. AWS Lambda Functions
3. Ensure you have following items ready prior to launching Terraform:
    1. S3 buckets to host Terraform state files for
        1. Networking  - sets up network that would be used by API Gateway, Lambdas & Web Tier;           set in `network/backend-config.tfvars`
        2. Lambdas     - spins up Lambda Functions that are to be called from Web Tier (via API Gateway); set in `lambdas/backend-config.tfvars`
        3. API Gateway - sets up API Gateway: linkage between Web-Tier and Lambdas + authentication;      set in `api-gateway/backend-config.tfvars & api-gateway/data.tf >> data >> config >> bucket & region (same as what set in network)`
        4. Web Tier    - sets up servers hosted in public subnets; accessible via Internet;               set in `web-tier/backend-config.tfvars    & web-tier/data.tf    >> data >> config >> bucket & region (same as what set in network & api-gateway)`
        5. Route53     - links custom DNS (with HTTPS cert) to Web Tier LB;                               set in `route53/backend-config.tfvars     & route53/data.tf     >> data >> config >> bucket & region (same as what set in web-tier)`
    2. `terraform.tfvars` file in each of the module: `app-tier`, `network`, `route53`, `web-tier` to specify:
        1. TLS certificates (specifically ARN of those) - these would be used to ensure HTTPS connectivity is properly handled
        2. SSH Keys - so you would be able to log onto Web Tier servers in case you need to debug/play around with those
    3. `backend-config.tfvars` file in each of the module: `app-tier`, `network`, `route53`, `web-tier` to specify:
        1. `bucket` - backend bucket
        2. `key`    - backend key
        3. `region` - backend region
4. Items should be deployed in the following order:
    1. `network`  - creates all network related resources
    ```
    # Required only once or whenever backend config changes
    terraform init -backend-config=backend-config.tfvars

    terraform plan  -var-file=terraform.tfvars -var-file=backend-config.tfvars
    terraform apply -var-file=terraform.tfvars -var-file=backend-config.tfvars -auto-approve
    ```
    2. `lambdas` - creates all required AWS Lambda Functions
    ```
    # Required only once or whenever backend config changes
    terraform init -backend-config=backend-config.tfvars

    terraform plan  -var-file=terraform.tfvars -var-file=backend-config.tfvars
    terraform apply -var-file=terraform.tfvars -var-file=backend-config.tfvars -auto-approve
    ```
    3. `api-gateway` - creates all AppTier (backend) related resources;   depends on the output of `network`
    ```
    # Required only once or whenever backend config changes
    terraform init -backend-config=backend-config.tfvars

    terraform plan  -var-file=terraform.tfvars -var-file=backend-config.tfvars
    terraform apply -var-file=terraform.tfvars -var-file=backend-config.tfvars -auto-approve
    ```
    4. `web-tier` - creates all WebTier (front end) related resources; depends on the output of `network` & `app-tier`
    ```
    # Required only once or whenever backend config changes
    terraform init -backend-config=backend-config.tfvars

    terraform plan  -var-file=terraform.tfvars -var-file=backend-config.tfvars
    terraform apply -var-file=terraform.tfvars -var-file=backend-config.tfvars -auto-approve
    ```
    5. `route53` - links custom DNS (with HTTPS cert) to Web Tier LB; depends on the output of `web-tier`
    ```
    # Required only once or whenever backend config changes
    terraform init -backend-config=backend-config.tfvars

    terraform plan  -var-file=terraform.tfvars -var-file=backend-config.tfvars
    terraform apply -var-file=terraform.tfvars -var-file=backend-config.tfvars -auto-approve
    ```


## Authentication
By default, AWS provider expects `default` AWS Config & Crendentials (this could be changed)
```
# from main.tf
provider "aws" {
  region  = "eu-west-2"
  profile = "default"
}

# cat ~/.aws/config
[default]
region = eu-west-2
output = json

# cat ~/.aws/credentials
[default]
aws_access_key_id     = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
```


## Remove infrastructure
1. At the moment it is not nicely implemented, so the only way to remove created infrastructure, is to
```
1. Comment out everything in main.tf & outputs.tf(if exists) for each deployed module
2. Run `terraform apply` in the following order (effectively in the reverse)
    1. Route53
    2. Web Tier
    3. API Gateway
    4. Lambdas
    5. Networks
```


## Notes:
1. Tested with **Terraform v1.4.0**
