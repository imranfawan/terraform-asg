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
  #source                  = "../"
  source                  = "github.com/imranfawan/terraform-asg?ref=v1.0"
  node_name_prefix        = var.node_name_prefix
  image_id                = var.image_id
  ssh_source_ip           = var.ssh_source_ip
  key_name                = var.key_name
  min_size                = var.min_size
  desired_capacity        = var.desired_capacity
  max_size                = var.max_size
  vpc_zone_identifier     = ["${module.vpc.subnet_pvt_id_1a}", "${module.vpc.subnet_pvt_id_1b}", "${module.vpc.subnet_pvt_id_1c}"]
  availability_zones      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id                  = module.vpc.vpc_id
  notification_target_arn = module.sns.notification_target_arn
  role_arn                = module.sns.role_arn
}