
resource "aws_vpc" "C_VPC" {
    for_each    = var.networks
    cidr_block  = each.value.cidr_block
    tags = {
        Name = each.key
    }
}

resource "aws_subnet" "C_Network" {
    depends_on = [ aws_vpc.C_VPC ]
    for_each = tomap({
        for subnet in local.network_subnets : "${subnet.network_key}.${subnet.tag_name}" => subnet
    })
    vpc_id            = each.value.vpc_id
    availability_zone = each.value.zone
    cidr_block        = each.value.cidr_block
    tags = {
        Name = each.value.tag_name
    }
}


# # Create Instance
# resource "aws_instance" "server" {
#   count                       = length(var.vms)
#   ami                         = var.vms[count.index]["image"]
#   instance_type               = var.vms[count.index]["type"]
#   subnet_id                   = resource.aws_subnet.C_Network.id
#   monitoring                  = false
#   associate_public_ip_address = false
#   source_dest_check           = true
# #   depends_on = [
# #     aws_subnet.C_VPC,
# #     aws_subnet.C_Network
# # #    aws_security_group.ext
# #   ]
#   #vpc_security_group_ids = [aws_security_group.ext.id]

# #   ebs_block_device {
# #     delete_on_termination = false
# #     device_name           = "disk1"
# #     volume_type           = var.vms[count.index]["volume_type"]
# #     volume_size           = var.vms[count.index]["volume_size"]
# #     tags = {
# #       Name = var.vms[count.index]["name"]
# #     }
# #   }
# #   tags = {
# #     Name = var.vms[count.index]["name"]
# #   }
# }



























#----------------------------------------------------------------------------





