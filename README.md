# AWS Cloudfront Redirect

Terraform module to setup an HTTP (302) redirect using AWS Cloudfront

### Advantages
- *Very* cheap, uses only CF Functions, can cost pennies for a moderate trafficked site
- SSL support and automated renewals with ACM
- No external dependencies

### Requirements
1. AWS account with admin access to Route53 and Cloudfront
2. Public domain, with DNS hosted by a R53 Zone.

## How to use
### One redirect
`main.tf`
```hcl
#redirect example.org to example.com
module "aws-cf-redirect" {
    source = "git@github.com:observeinc/terraform-aws-cf-redirect.git?ref=v1.3.0"
    destination = "https://example.com"
    domain = "domain.org"
    route53_zone_id = "XXXXXXX"
}
```

### List of redirects
`main.tf`
```hcl
module "aws-cf-redirect" {
    source = "git@github.com:observeinc/terraform-aws-cf-redirect.git?ref=v1.3.0"

    for_each = {
        for index, redirect in var.redirects :
        redirect.domain => redirect
    }

    route53_zone_id    = each.value.route53_zone_id
    domain             = each.value.domain
    destination        = each.value.destination
    is_static_redirect = each.value.is_static_redirect
    custom_cf_function = each.value.custom_cf_function == "" ? "" : file(each.value.custom_cf_function) #Return "" if empty, otherwise, grab the file.
}
```

`variables.tf`
```hcl
variable "redirects" {
  type = list(object({
    domain             = string,
    destination        = string,
    route53_zone_id    = string,
    is_static_redirect = bool,
    custom_cf_function = string
  }))
  description = "List of redirects to create."
}
```
More information about Cloudfront Functions: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_route53_record.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cloudfront_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [random_string.aws_cloudfront_function_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_cf_function"></a> [custom\_cf\_function](#input\_custom\_cf\_function) | Specify a custom function to use for the Cloudfront function. If blank, the default will be used. Example: cloudfront\_custom\_function.js | `string` | `""` | no |
| <a name="input_destination"></a> [destination](#input\_destination) | redirect destination. Entire URL, eg https://google.com | `string` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Fully qualified domain to redirect from. | `string` | n/a | yes |
| <a name="input_is_static_redirect"></a> [is\_static\_redirect](#input\_is\_static\_redirect) | If this is enabled, the path will not be passed with the redirect. | `bool` | `false` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | ID of the Route53 DNS zone. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_cloudfront_distribution_id"></a> [aws\_cloudfront\_distribution\_id](#output\_aws\_cloudfront\_distribution\_id) | AWS Cloudfront Distribution ID |
| <a name="output_aws_cloudfront_function_id"></a> [aws\_cloudfront\_function\_id](#output\_aws\_cloudfront\_function\_id) | AWS Cloudfront Function ID |
<!-- END_TF_DOCS -->