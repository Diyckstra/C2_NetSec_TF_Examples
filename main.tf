
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

##################################################################################################### Interfaces
# Interfaces
locals {
  Secondary_interfaces = flatten([
    for name, vms in var.vms_SG : [
      for idx, interface in vms.secondary_ifs:
        {
          interface = interface.interface 
          vm = name # local.Firewalls_by_name[name]
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
    aws_security_group.Creating_SG
  ]
  count = length(local.Secondary_interfaces)
  description = "${local.Secondary_interfaces[count.index].vm}_IF_${local.Secondary_interfaces[count.index].device_index}_${local.Secondary_interfaces[count.index].subnet}"
  subnet_id   = local.Secondary_interfaces[count.index].subnet
  private_ips = [local.Secondary_interfaces[count.index].interface]
  security_groups = [local.Secondary_interfaces[count.index].sg]
  source_dest_check = false

  tags = {
    Name = "${local.Secondary_interfaces[count.index].vm}_IF_${local.Secondary_interfaces[count.index].device_index}_${local.Secondary_interfaces[count.index].subnet}"
  }
}

##################################################################################################### Instances
# Instances SG
resource "aws_instance" "Creating_Instances_SG" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG,
    aws_network_interface.Creating_Secondary_Ifaces
  ]
  for_each = var.vms_SG

  ami                         = each.value.image
  instance_type               = each.value.type
  availability_zone           = each.value.zone
  monitoring                  = false

  associate_public_ip_address = false
  source_dest_check           = false

  private_ip                  = each.value.main_interface
  subnet_id                   = local.Subnet_IDs_by_name[each.value.subnet]
  vpc_security_group_ids      = [local.SG_IDs_by_name[each.value.security_group]]

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

# Instances SMS
resource "aws_instance" "Creating_Instances_SMS" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG
  ]
  for_each = var.vms_SMS

  ami                         = each.value.image
  instance_type               = each.value.type
  availability_zone           = each.value.zone
  monitoring                  = false

  associate_public_ip_address = false
  source_dest_check           = true

  private_ip                  = each.value.main_interface
  subnet_id                   = local.Subnet_IDs_by_name[each.value.subnet]
  vpc_security_group_ids      = [local.SG_IDs_by_name[each.value.security_group]]

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

# pause for creating instances
resource "time_sleep" "wait_three_minutes" {
  depends_on = [
    aws_instance.Creating_Instances_SG,
    aws_instance.Creating_Instances_SMS
  ]
  create_duration = "150s"
}

##################################################################################################### Passwords
# Passwords
# Configure random password for each VM SG
resource "random_password" "Creating_password_SG" {
  count             = length(aws_instance.Creating_Instances_SG) * 4
  length            = 16
  special           = true
  override_special  = "%!#$&*"
}

# Configure random password for each VM SMS
resource "random_password" "Creating_password_SMS" {
  count             = length(aws_instance.Creating_Instances_SMS) * 4
  length            = 16
  special           = true
  override_special  = "%!#$&*"
}

# Configure random first SIC
resource "random_password" "Creating_first_SIC" {
  count             = length(aws_instance.Creating_Instances_SG)
  length            = 12
  special           = true
  override_special  = "!$"
}

locals {
  sic_passwords = [
    for index, p in values(aws_instance.Creating_Instances_SG) : {
      name = p.tags["Name"]
      ip   = p.private_ip
      sic  = random_password.Creating_first_SIC[index].result
    }
  ]
  Firewalls_by_name = { for name, obj in aws_instance.Creating_Instances_SG : name => obj.id }
  SMS_by_name = { for name, obj in aws_instance.Creating_Instances_SMS : name => obj.id }
}

resource "aws_network_interface_attachment" "Attachment_Secondary_Ifs" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG,
    aws_instance.Creating_Instances_SG,
    aws_network_interface.Creating_Secondary_Ifaces,
    time_sleep.wait_three_minutes
  ]
  count                 = length(local.Secondary_interfaces)
  instance_id           = local.Firewalls_by_name[
    local.Secondary_interfaces[count.index].vm
  ]
  network_interface_id  = aws_network_interface.Creating_Secondary_Ifaces[count.index].id
  device_index          = local.Secondary_interfaces[count.index].device_index
}

##################################################################################################### EIP
# EIP
resource "aws_eip" "Creating_EIPs_SG" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG,
    aws_instance.Creating_Instances_SG
    ]
  count = length(aws_instance.Creating_Instances_SG)
  instance = values(aws_instance.Creating_Instances_SG)[count.index].id
  vpc      = true
  tags = {
    Name = values(aws_instance.Creating_Instances_SG)[count.index].tags.Name
  }
}

resource "aws_eip" "Creating_EIPs_SMS" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG,
    aws_instance.Creating_Instances_SMS
    ]
  count = length(aws_instance.Creating_Instances_SMS)
  instance = values(aws_instance.Creating_Instances_SMS)[count.index].id
  vpc      = true
  tags = {
    Name = values(aws_instance.Creating_Instances_SMS)[count.index].tags.Name
  }
}

##################################################################################################### Ansible
# Ansible
# Creating inventory for Ansible in .yml
resource "local_file" "hosts_yaml" {
  depends_on = [
    aws_instance.Creating_Instances_SG,
    aws_eip.Creating_EIPs_SG,
    random_password.Creating_password_SG,
    time_sleep.wait_three_minutes
  ]
  content = templatefile("inventory.tftpl",
           {
            valid_ips       = var.admin.valid_ips

            SG_instance         = values(aws_instance.Creating_Instances_SG)[*].tags.Name
            SG_ip               = aws_eip.Creating_EIPs_SG[*].public_ip
            SG_admin_password   = [for i, p in random_password.Creating_password_SG : p.result if i % 4 == 0]
            SG_expert_password  = [for i, p in random_password.Creating_password_SG : p.result if i % 4 == 1]
            SG_grub2_password   = [for i, p in random_password.Creating_password_SG : p.result if i % 4 == 2]
            SG_api_password     = [for i, p in random_password.Creating_password_SG : p.result if i % 4 == 3]

            SG_sic_password     = [for i, p in random_password.Creating_first_SIC : p.result]

            SMS_instance        = values(aws_instance.Creating_Instances_SMS)[*].tags.Name
            SMS_ip              = aws_eip.Creating_EIPs_SMS[*].public_ip
            SMS_admin_password  = [for i, p in random_password.Creating_password_SMS : p.result if i % 4 == 0]
            SMS_expert_password = [for i, p in random_password.Creating_password_SMS : p.result if i % 4 == 1]
            SMS_grub2_password  = [for i, p in random_password.Creating_password_SMS : p.result if i % 4 == 2]
            SMS_api_password    = [for i, p in random_password.Creating_password_SMS : p.result if i % 4 == 3]
            gateways_name       = local.sic_passwords[*].name
            gateways_ip         = local.sic_passwords[*].ip
            gateways_sic        = local.sic_passwords[*].sic
           })
        filename = "Ansible/inventory.yml"
}

# # play_ansible for security gateways
# resource "terraform_data" "FTW" {

#   depends_on = [ time_sleep.wait_three_minutes ]

#   # # Replacement of any instance of the cluster requires re-provisioning
#   # triggers_replace = aws_instance.Creating_Instances_SG[*].id

#   provisioner "local-exec" {
#     command = "ansible-playbook Ansible/playbook.yml -i Ansible/inventory.yml"
#   }
# }

##################################################################################################### VIP Interfaces
# VIP Interfaces
# locals {
#   VIP_interfaces = flatten([
#     for name, vms in var.vms_SG : [
#       for idx, interface in vms.secondary_ifs:
#         {
#           interface = interface.interface 
#           vm = name # local.Firewalls_by_name[name]
#           subnet = local.Subnet_IDs_by_name[interface.subnet],
#           sg = local.SG_IDs_by_name[interface.sg],
#           device_index = idx + 1
#         }
#     ]
#   ])
# }

resource "aws_network_interface" "Creating_VIP_Ifaces" {
  depends_on = [
    aws_vpc.Creating_VPC,
    aws_subnet.Creating_Subnet,
    aws_security_group.Creating_SG,
    time_sleep.wait_three_minutes
  ]

  count = length(var.vip_fw_interfaces)

  description = "VIP_for_${local.Subnet_IDs_by_name[var.vip_fw_interfaces[count.index].subnet]}"
  subnet_id   = local.Subnet_IDs_by_name[var.vip_fw_interfaces[count.index].subnet]
  private_ips = [var.vip_fw_interfaces[count.index].interface]
  security_groups = [local.SG_IDs_by_name[var.vip_fw_interfaces[count.index].sg]]
  source_dest_check = false

  tags = {
    Name = "VIP_for_${local.Subnet_IDs_by_name[var.vip_fw_interfaces[count.index].subnet]}"
  }
}







# cluster eips
# route table
# tgw
# 