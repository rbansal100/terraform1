#### Terraform code to provision resources in IBM Cloud
#### Ravi B

##### Provider block - common to all TF files that will be executed to build infra
terraform {
  required_version = ">=1.0.0, <2.0"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}


#### Set region ion which the this TF file will operate #####
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = "us-south"

}


##### Get resource group ID for existing resource group with the given name ###
##### You can also create a new res grp here #####
data "ibm_resource_group" "group" {
  name = "default"
}



#### get ssh key for existing key with the given name   ####
#### you can also create new ssh key here ############
data "ibm_is_ssh_key" "ssh_key" {
  name = "mysshkeyforvpc"
}

####### set project prefix for any naming convention ###
locals {
  project_prefix = "xxx"

}


##### create vpc ########

resource "ibm_is_vpc" "vpc1" {
  name           = "${local.project_prefix}-vpc"
  resource_group = data.ibm_resource_group.group.id

}




#### Add a rule to the default security group to allow ssh-based access
resource "ibm_is_security_group_rule" "ssh_rule" {
  group     = ibm_is_vpc.vpc1.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}



########create vpc subnet ########
########## note the zone name ##########

resource "ibm_is_subnet" "subnet1" {
  name                     = "${local.project_prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "us-south-1"
  total_ipv4_address_count = 256


}

############ Image for Virtual Server Instance ########
data "ibm_is_image" "centos" {
  name = "ibm-centos-7-6-minimal-amd64-1"
}

########create vsi in subnet with ssh access ########
resource "ibm_is_instance" "vsi1" {
  name    = "${local.project_prefix}-vsi1"
  vpc     = ibm_is_vpc.vpc1.id
  zone    = "us-south-1"
  profile = "bx2-2x8"
  keys    = [data.ibm_is_ssh_key.ssh_key.id]
  image   = data.ibm_is_image.centos.id
  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }

}


############# Attach a floating IP  ###############
resource "ibm_is_floating_ip" "fip1" {
  name   = "${local.project_prefix}-fip1"
  target = ibm_is_instance.vsi1.primary_network_interface[0].id
}

