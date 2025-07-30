

resource "aws_acm_certificate" "this" {
  provider          = aws.us-east-1
  domain_name       = local.fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "this_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.this_acm_validation : record.fqdn]
}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "this" {

  origin {
    domain_name = aws_s3_bucket_website_configuration.this.website_endpoint
    origin_id   = aws_s3_bucket.this_website.bucket_regional_domain_name


    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  aliases = [local.fqdn]
  enabled = true

  default_cache_behavior {
    cache_policy_id  = data.aws_cloudfront_cache_policy.this.id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.this_website.bucket_regional_domain_name


    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.this.id
    ssl_support_method  = "sni-only"
  }
}