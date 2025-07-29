variable "domain" {
  description = "Source domain"
  type        = string
}

variable "hostname" {
  description = "Source hostname"
  type        = string
}

variable "index" {
  description = "Index document"
  type        = string
  default     = "index.html"
}

variable "error" {
  description = "Error document"
  type        = string
  default     = "error.html"
}