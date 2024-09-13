# Administrator VARs
# Configure AWS access_key

variable "admin" {
  type = map(string)
  default = {
    "name"              = "admin"
    "secret_key"        = "",
    "access_key"        = "",
    "SSH_private_path"  = "",
    "SSH_public_key"    = ""
  }
}

###############################################################

# Network VARs
variable "networks" {
  type = map(
    object({
      cidr_block = string
      default = bool
      subnets = map(
        object(
          {
            cidr_block = string
            zone = string
          
          }
        )
      )
    })
  )
  default = {
    VPC_1 = {
      cidr_block = "10.0.0.0/16",
      default = false,
      subnets = {
        DMZ = {
          cidr_block = "10.0.1.0/24",
          zone = "ru-msk-comp1p"
        },
        DB_Servers = {
          cidr_block = "10.0.2.0/24",
          zone = "ru-msk-comp1p"
        },
        Servers_1 = {
          cidr_block = "10.0.3.0/24",
          zone = "ru-msk-comp1p"
        },
        Servers_2 = {
          cidr_block = "10.0.4.0/24",
          zone = "ru-msk-comp1p"
        }
      }
    }
    VPC_2 = {
      cidr_block = "10.1.0.0/16",
      default = false,
      subnets = {
        DMZ = {
          cidr_block = "10.1.1.0/24",
          zone = "ru-msk-vol51"
        },
        DB_Servers = {
          cidr_block = "10.1.2.0/24",
          zone = "ru-msk-vol51"
        },
        Servers_1 = {
          cidr_block = "10.1.3.0/24",
          zone = "ru-msk-vol51"
        },
        Servers_2 = {
          cidr_block = "10.1.4.0/24",
          zone = "ru-msk-vol51"
        }
      }
    }
  }
}

###############################################################

# VM VARs
variable "vms" {
  type = list(map(any))
  default = [
    {
      "name" : "Check Point SMS R81.20",
      "image" : "cmi-76C60AE5",
      "type" : "c5.2large",
      "volume_type" : "gp2",
      "volume_size" : 320
    }
  ]
}
