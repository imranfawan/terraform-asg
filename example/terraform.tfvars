
node_name_prefix = "demo-asg"
image_id         = "ami-09ba01d9b2eb740ba" # Ubuntu 18.04
ssh_source_ip    = "<SOURCE_IP>"
key_name         = "<KEY_PAIR_NAME>" # key pair in aws to connect to the instances if required
min_size         = 1
desired_capacity = 2
max_size         = 2