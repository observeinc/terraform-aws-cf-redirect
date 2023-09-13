variable "domain" {
    type = string
    description = "Fully qualified domain to redirect from."
}

variable "desination" {
    type = string
    description = "redirect destination. Entire URL, eg https://google.com"
}

variable "route53_zone_id" {
    type = string
    description = "ID of the Route53 DNS zone."
}

variable "is_static_redirect" {
  type = bool
  default = false
  description = "If this is enabled, the path will not be passed with the redirect."
}