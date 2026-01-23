variable "ssh_public_key_path" {
  description = "SSH public key file path for accessing the server"
  type        = string
}

variable "ssh_private_key_path" {
  description = "SSH private key file path for accessing the server"
  type        = string
  default     = ""
}

