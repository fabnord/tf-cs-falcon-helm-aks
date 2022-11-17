variable "falcon_cid" {
  type = string
  description = "Falcon CID including checksum (00000000000000000000000000000000-00)."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{32}-[0-9a-fA-F]{2}$", var.falcon_cid))
    error_message = "Falcon CID is not correct. Please ensure the CID includes the checksum."
  }
}

variable "falcon_cloud_region" {
  type    = string
  default = "us-1"
  validation {
    condition     = contains(["us-1", "us-2", "eu-1"], var.falcon_cloud_region)
    error_message = "Falcon Cloud Region is not correct. Please ensure it's set to us-1, us2 or eu-1."
  }
}

variable "falcon_cliend_id" {
  type = string
}

variable "falcon_client_secret" {
  type      = string
  sensitive = true
}

variable "falcon_sensor_cr_token" {
  type      = string
  sensitive = true
}

variable "falcon_kpa_cr_token" {
  type      = string
  sensitive = true
}

variable "azure_aks_name" {
  type = string
}

variable "azure_aks_resource_group" {
  type = string
}
