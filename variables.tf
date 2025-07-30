variable "domain" {
  description = "Source domain"
  type        = string
}

variable "hostname" {
  description = "Source hostname"
  type        = string
  default     = null
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

variable "content_path" {
  description = "Local content directory"
  type        = string
}

variable "mime_types" {
  type = map(string)
  default = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    svg  = "image/svg+xml"
    json = "application/json"
    txt  = "text/plain"
  }
}