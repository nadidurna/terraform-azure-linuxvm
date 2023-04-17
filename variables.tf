variable "host_os" {
  type    = string
  default = "windows"
}
variable "rg_name" {
  type    = string
  default = "nadi-tf"

}
variable "location" {
  type    = string
  default = "West Europe"

}
variable "vnet_name" {
  type    = string
  default = "vnet-tf"

}
variable "nsg_name" {
  type    = string
  default = "nsg-tf"

}
variable "nsg_rule_name" {
  type    = string
  default = "nsg-rule-tf"

}
variable "public_ip_name" {
  type    = string
  default = "public-ip-tf"

}
variable "nic_name" {
  type    = string
  default = "nic-tf"

}
variable "vm_name" {
  type    = string
  default = "linux-vm-tf"

}