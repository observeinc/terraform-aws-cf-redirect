output "aws_cloudfront_distribution_id" {
    description = "AWS Cloudfront Distribution ID"
    value = aws_cloudfront_distribution.main.id
}

output "aws_cloudfront_function_id" {
    description = "AWS Cloudfront Function ID"
    value = aws_cloudfront_function.redirect.id
}