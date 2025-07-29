locals {
  fqdn = try(
    "${var.hostname}.${var.domain}",
    "${var.domain}",
  )
}