locals {
  network_subnets = flatten([
    for network_key, network in var.networks : [
      for subnet_key, subnet in network.subnets : {
        network_key = network_key
        zone        = subnet.zone
        vpc_id      = aws_vpc.C_VPC[network_key].id
        cidr_block  = subnet.cidr_block
        tag_name    = subnet_key
      }
    ]
  ])
}