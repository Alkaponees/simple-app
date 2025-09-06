output "ec2_public_ip" {
  value = aws_eip.app_eip.public_ip
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}