# Administrator VARs
# Configure AWS access_key

variable "admin" {
#  type = map(any)
  default = {
    "name"              = "",
    "secret_key"        = "",
    "access_key"        = "",
    "SSH_private_path"  = "",
    "SSH_public_key"    = "",
    "valid_ips"         = []
  }
}

###############################################################

variable "VPCs" {
  default = {
    FW_VPC = "10.255.0.0/16",
    VPC_0 = "10.0.0.0/16",
    VPC_1 = "10.1.0.0/16",
  }
}

variable "SecurityGroups" {
  default = {
    FW_VPC_Ext_SG = {
      vpc_name  = "FW_VPC"
      from_ip   = ["195.38.23.0/24", "176.99.159.90/32", "10.255.255.0/24"]
      to_ip     = ["0.0.0.0/0"]
    },
    FW_VPC_Int_SG = {
      vpc_name  = "FW_VPC"
      from_ip   = ["0.0.0.0/0"]
      to_ip     = ["0.0.0.0/0"]
    },
    VPC_0_Int_SG = {
      vpc_name  = "VPC_0"
      from_ip   = ["0.0.0.0/0"]
      to_ip     = ["0.0.0.0/0"]
    },
    VPC_1_Int_SG = {
      vpc_name  = "VPC_1"
      from_ip   = ["0.0.0.0/0"]
      to_ip     = ["0.0.0.0/0"]
    }
  }
}

# Network VARs
variable "Networks" {
  default = [
    {
      name        = "Output",
      cidr_block  = "10.255.255.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "FW_VPC"
    },
    {
      name        = "Transit_01",
      cidr_block  = "10.255.0.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "FW_VPC"
    },
    {
      name        = "Transit_02",
      cidr_block  = "10.255.1.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "FW_VPC"
    },
    {
      name        = "Transit_1",
      cidr_block  = "10.0.0.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "VPC_0"
    },
    {
      name        = "Servers_1",
      cidr_block  = "10.0.1.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "VPC_0"
    },
    {
      name        = "Servers_2",
      cidr_block  = "10.0.2.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "VPC_0"
    },
    {
      name        = "Servers_3",
      cidr_block  = "10.0.3.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "VPC_0"
    },
    {
      name        = "Transit_2",
      cidr_block  = "10.1.0.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "VPC_1"
    },
    {
      name        = "DMZ_1",
      cidr_block  = "10.1.1.0/24",
      zone        = "ru-msk-comp1p",
      vpc_name    = "VPC_1"
    }
  ]
}

###############################################################

# VM VARs
variable "vms_SG" {
  type = object({
    node_1 = object({
      name = string
      image = string
      type = optional(string, "c5.2large")
      zone = string
      vpc_name = string
      subnet = string
      main_interface = string
      security_group = string
      secondary_ifs = list(object({
        subnet = string
        interface = string
        sg = string
      }))
      volume_type = optional(string, "gp2")
      volume_size = optional(number, 216)
  })
    node_2 = object({
      name = string
      image = string
      type = optional(string, "c5.2large")
      zone = string
      vpc_name = string
      subnet = string
      main_interface = string
      security_group = string
      secondary_ifs = list(object({
        subnet = string
        interface = string
        sg = string
      }))
      volume_type = optional(string, "gp2")
      volume_size = optional(number, 216)
  })

})

  default = {
    node_1 = {

      # General
      name            = "Check_Point_SG_R81.20_1",
      image           = "cmi-AB267A9E",
      type            = "c5.2large",
      zone            = "ru-msk-comp1p",

      # Network
      vpc_name        = "FW_VPC",
      subnet          = "Output",
      main_interface  = "10.255.255.5"
      security_group  = "FW_VPC_Ext_SG",

      secondary_ifs   = [
        {
          subnet = "Transit_01",
          interface = "10.255.0.5",
          sg = "FW_VPC_Int_SG"
        },
        {
          subnet = "Transit_02",
          interface = "10.255.1.5",
          sg = "FW_VPC_Int_SG"
        }
      ],

      # Disk
      volume_type     = "gp2",
      volume_size     = 216,
    },
    node_2 = {

      # General
      name            = "Check_Point_SG_R81.20_2",
      image           = "cmi-AB267A9E",
      type            = "c5.2large",
      zone            = "ru-msk-comp1p",

      # Network
      vpc_name        = "FW_VPC",
      subnet          = "Output",
      main_interface  = "10.255.255.6"
      security_group  = "FW_VPC_Ext_SG",

      secondary_ifs   = [
        {
          subnet = "Transit_01",
          interface = "10.255.0.6",
          sg = "FW_VPC_Int_SG"
        },
        {
          subnet = "Transit_02",
          interface = "10.255.1.6",
          sg = "FW_VPC_Int_SG"
        }
      ],

      # Disk
      volume_type     = "gp2",
      volume_size     = 216,
    }
}
}


###############################################################

# VM SMS
variable "vms_SMS" {
  type = object({
    SMS = object({
      name = string
      image = string
      type = optional(string, "c5.2large")
      zone = string
      vpc_name = string
      subnet = string
      main_interface = string
      security_group = string
      volume_type = optional(string, "gp2")
      volume_size = optional(number, 320)
  })
})
  default = {
    SMS = {

      # General
      name            = "Check_Point_SMS_R81.20_1",
      image           = "cmi-AB267A9E",
      type            = "c5.2large",
      zone            = "ru-msk-comp1p",

      # Network
      vpc_name        = "FW_VPC",
      subnet          = "Output",
      main_interface  = "10.255.255.10"
      security_group  = "FW_VPC_Ext_SG",

      # Disk
      volume_type     = "gp2",
      volume_size     = 320,
    }
}
}

###############################################################

variable "vip_fw_interfaces" {
  type = list(object({
    subnet = string
    interface = string
    sg = string
    wan = bool
  }))
  
  default = [
    {
      subnet = "Output",
      interface  = "10.255.255.4",
      sg  = "FW_VPC_Ext_SG",
      wan = true
    },
    {
      subnet = "Transit_01",
      interface = "10.255.0.4",
      sg = "FW_VPC_Int_SG",
      wan = false
    },
    {
      subnet = "Transit_02",
      interface = "10.255.1.4",
      sg = "FW_VPC_Int_SG",
      wan = false
    }
  ]
}

###############################################################
