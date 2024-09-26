
##################################################################################################### VPC
# VPC
resource "aws_vpc" "Creating_VPC" {
    for_each = var.VPCs

    cidr_block  = each.value
    tags = {
        Name = each.key
    }
}

locals {
  VPC_IDs_by_name = { for name in keys(var.VPCs) : name => aws_vpc.Creating_VPC[name].id }
}

##################################################################################################### Security Groups
# Security Groups
resource "aws_security_group" "Creating_SG" {
  depends_on = [ aws_vpc.Creating_VPC ]
  for_each = var.SecurityGroups

  vpc_id      = local.VPC_IDs_by_name[each.value.vpc_name]
  name        = each.key
  description = each.key

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = each.value.from_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = each.value.to_ip
  }

  tags = {
    Name = each.value.vpc_name
  }
}

locals {
  SG_IDs_by_name = { for name, obj in aws_security_group.Creating_SG : name => obj.id }
}

##################################################################################################### Subnets
# Subnets
resource "aws_subnet" "Creating_Subnet" {
    depends_on = [ aws_vpc.Creating_VPC ]
    count = length(var.Networks)

    vpc_id            = local.VPC_IDs_by_name[var.Networks[count.index].vpc_name]
    availability_zone = var.Networks[count.index].zone
    cidr_block        = var.Networks[count.index].cidr_block
    tags = {
        Name = var.Networks[count.index].name
    }
}

locals {
  Subnet_IDs_by_name = { for idx, name in var.Networks[*].name : name => aws_subnet.Creating_Subnet[idx].id }
}

##################################################################################################### Instances
# Instances
resource "aws_instance" "Creating_Instances" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG
  ]
  for_each = var.vms

  ami                         = each.value.image
  instance_type               = each.value.type
  availability_zone           = each.value.zone
  monitoring                  = false

  associate_public_ip_address = false
  source_dest_check           = true

  private_ip                  = each.value.main_interface
  subnet_id                   = local.Subnet_IDs_by_name[each.value.subnet]
  vpc_security_group_ids      = [local.SG_IDs_by_name[each.value.security_group]]

  # network_interface {
  #   network_interface_id = aws_network_interface.example.id
  #   device_index         = 1
  # }

  ebs_block_device {
    delete_on_termination = true
    device_name           = "disk1"
    volume_type           = each.value.volume_type
    volume_size           = each.value.volume_size
    tags = {
      Name = each.value.name
    }
  }

  tags = {
    Name = each.value.name
  }
}

locals {
  Firewalls_by_name = { for name, obj in aws_instance.Creating_Instances : name => obj.id }
}

##################################################################################################### EIP
# EIP
resource "aws_eip" "Creating_EIPs" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG,
    aws_instance.Creating_Instances
    ]
  count = length(aws_instance.Creating_Instances)
  instance = values(aws_instance.Creating_Instances)[count.index].id
  vpc      = true
  tags = {
    Name = values(aws_instance.Creating_Instances)[count.index].tags.Name
  }
}

##################################################################################################### Interfaces
# Interfaces
locals {
  Secondary_interfaces = flatten([
    for name, vms in var.vms : [
      for idx, interface in vms.secondary_ifs:
        {
          interface = interface.interface 
          vm = local.Firewalls_by_name[name]
          subnet = local.Subnet_IDs_by_name[interface.subnet],
          sg = local.SG_IDs_by_name[interface.sg],
          device_index = idx + 1
        }
    ]
  ])
}

resource "aws_network_interface" "Creating_Secondary_Ifaces" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG,
    aws_instance.Creating_Instances,
    aws_eip.Creating_EIPs
  ]
  count = length(local.Secondary_interfaces)

  description = local.Secondary_interfaces[count.index].vm
  subnet_id   = local.Secondary_interfaces[count.index].subnet
  private_ips = [local.Secondary_interfaces[count.index].interface]
  security_groups = [local.Secondary_interfaces[count.index].sg]
  source_dest_check = false

  attachment {
    instance     = local.Secondary_interfaces[count.index].vm
    device_index = local.Secondary_interfaces[count.index].device_index
  }

  tags = {
    Name = local.Secondary_interfaces[count.index].vm
  }
}

#####################################################################################################

# cluster ips
# route table
# tgw
# 