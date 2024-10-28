
# VPC
output "VPC_ID" {
  value = local.VPC_IDs_by_name
}

# Security Groups
output "SG_ID" {
  value = local.SG_IDs_by_name
}

# Subnets
output "Subnet_ID" {
  value = local.Subnet_IDs_by_name
}

# Instances
output "Instances_ID_SG" {
  value = local.Firewalls_by_name
}

output "Instances_ID_SMS" {
  value = local.SMS_by_name
}

# Interfaces
output "Interface_Info" {
  value = local.Secondary_interfaces
}

# Interfaces
output "Interface_ID" {
  value = aws_network_interface.Creating_Secondary_Ifaces[*].id
}

output "SG_EIPs_ID" {
  value = aws_eip.Creating_EIPs_SG[*].public_ip
}

output "SMS_EIPs_ID" {
  value = aws_eip.Creating_EIPs_SMS[*].public_ip
}

output "Output_Attached_Interfaces" {
  value = aws_network_interface_attachment.Attachment_Secondary_Ifs
}
