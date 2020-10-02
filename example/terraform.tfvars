
node_name_prefix = "demo-asg"
image_id         = "ami-09ba01d9b2eb740ba" # Ubuntu 18.04
ssh_source_ip    = "82.44.251.204"
key_name         = "asg" # key pair in aws to connect to the instances if required
min_size         = 1
desired_capacity = 2
max_size         = 2

topic_name = "demo1"
sns_role_name = "notify_role"

vpc_name = "demo"
aws_region = "eu-west-1"
aws_zone_1a = "eu-west-1a"
aws_zone_1b = "eu-west-1b"
aws_zone_1c = "eu-west-1c"
