resource "aws_route53_record" "this" {

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.fqdn
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "this_website" {
  bucket = replace("${var.domain}-website", "_", "-")

  tags = {
    Name    = "${local.fqdn} Website"
    Website = true
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this_website.id

  index_document {
    suffix = var.index
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "this_website" {
  bucket = aws_s3_bucket.this_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

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


    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
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