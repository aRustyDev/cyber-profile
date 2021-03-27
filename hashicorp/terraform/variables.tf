#==========================================================
# Var Space - User set variables, that get reused ALOT
#==========================================================
# Set Hardcoded Variables
#==========================================================

# Set common name
variable "prefix" {
  default = "RedTeam"
}

# Set Default Admin Username
variable "admin_user" {
  default = "redadmin"
}

# Set Default Admin Password 
variable "admin_pass" {
  default = "password1234!@#$"  #Only keep this set during testing
}

# Set Default Region 
variable "region" {
  # default = "eastus"
  # default = "eastus2"
  default = "centralus"
  # default = "northcentralus"
  # default = "southcentralus"
  # default = "westcentralus"
  # default = "west"
  # default = "westus2"
}
# Set Second Region - ELK STACK PROJECT 13
variable "region_2" {
  # default = "eastus"
  # default = "eastus2"
  # default = "centralus"
  # default = "northcentralus"
  # default = "southcentralus"
  default = "westcentralus"
  # default = "west"
  # default = "westus2"
}

#==========================================================
# Set Interactive Variables - Use for setting up production
#==========================================================

# # Set Default Admin Username
# variable "admin_user" {
#   type = string
#   description = "Default Admin Username."
# }

# # Set Default Admin Password 
# variable "admin_pass" {
#   type = string
#   description = "Default Admin Password."
# }
