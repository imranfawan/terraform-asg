# Overview

This module creates an ASG that is spread across a number of specified subnets that are supplied as input values. This ASG is configured
to push it's event logs to a SNS topic. Like the subnets IDs the SNS topic's arn and topic name are supplied as input variables to the ASG module.

You may also dynamically append the subnet IDs and SNS vars by invoking the VPC and SNS modules as described below. The output values of these 
modules can then be passed as input variables to the ASG module. 

If the VPC and SNS modules alongside the ASG are run then this will result in the following resources:

   * VPC 
   * 6 Subnets- 3 pvt / 3 pub spread across each of the eu-west-1 zones - Subnets can be configured in the VPC module
   * SNS Topic (including the role / policy required to create a lifecycle_hook for the ASG)
   * Security Group to allow ingress traffic to the instances at port 80. Allows access to port 22 from configurable IP address
   * Auto Scaling Group within the subnets created above 

## Requirements

Ensure your development has the following installed and configured:

* Terraform version 12 or above
* Your `AWS_PROFILE` is set

## Usage

The `asg` module is called from the `provider/asg` folder and its `main.tf` and its example of the module's usage is as follows:

```{r, engine='bash', count_lines}

/**
terraform {
  backend "s3" {
    bucket = "<BUCKET>"
    key    = "<BUCKET>/terraform.tfstate"
    region = "<REGION>"
  }
}
**/

provider "aws" {
  version = "~> 2.7.0"
  region  = "eu-west-1"
}

module "vpc" {
  source = "github.com/imranfawan/terraform-vpc?ref=v1.0"
  vpc_name = "demo"
  aws_region = "eu-west-1"
  aws_zone_1a = "eu-west-1a"
  aws_zone_1b = "eu-west-1b"
  aws_zone_1c = "eu-west-1c"
}



module "sns" {
  source = "github.com/imranfawan/terraform-sns?ref=v1.0"
  topic_name = var.topic_name
  sns_role_name = var.sns_role_name
}


module "asg" {
  #source                   = "../"
  source                   = "github.com/imranfawan/terraform-asg?ref=v1.0"
  node_name_prefix         = var.node_name_prefix
  image_id                 = var.image_id
  ssh_source_ip            = var.ssh_source_ip
  key_name                 = var.key_name
  min_size                 = var.min_size
  desired_capacity         = var.desired_capacity
  max_size                 = var.max_size
  vpc_zone_identifier      = ["${module.vpc.subnet_pvt_id_1a}","${module.vpc.subnet_pvt_id_1b}","${module.vpc.subnet_pvt_id_1c}"]
  availability_zones      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id                   = module.vpc.vpc_id
  notification_target_arn  = module.sns.notification_target_arn
  role_arn                 = module.sns.role_arn   
}

```

Note that the values are passsed in from the 'terraform.tfvars' file

## Steps

(1) Browse to the `example/asg` folder

(2) In `example/main.tf` you can enable a s3 back-end to persist the state by uncommenting the `terraform` block and set   

the bucket name / key to store the state

(3) Some values passed into the ASG module can be sensitive such as the ssh key name and source IP address. In `terraform-scripts/provider/asg/terraform.tfvars` specify values as desired with the following as mandatory:

```bash
ssh_source_ip = "<SOURCE_IP>"
key_name     = "<KEY_PAIR_NAME>" # key pair in aws to connect to the instances if required
```

(4) From the `terraform-scripts/provider/asg` folder run the following commands

(5) `terraform init`

This will install the modules and aws plugins

(6) `terraform apply`

Note: The above usage will deploy the ASG to the newly created subnets. To deploy to existing subnets, comment out the `vpc module` block in the 
`terraform-scripts/provider/asg/main.tf` file and hard-code the subnet IDs to the `vpc_zone_identifier` as follows:

`vpc_zone_identifier  = ["<SUBNET_ID_1>","<SUBNET_ID_1>"]`

(7) Double check the resources created are as expected and enter `yes`



