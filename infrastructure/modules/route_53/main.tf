data "aws_route53_zone" "website" {
  name = "rekoglabelify.com"
}


resource "aws_route53_record" "website" {
  zone_id = data.aws_route53_zone.website.zone_id
  name    = "rekoglabelify.com"
  type    = "A"

  alias {
    name                   = var.aws_cloudfront_distribution_domain_name 
    zone_id                = var.aws_cloudfront_distribution_hosted_zone_id 
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "website_www" {
  zone_id = data.aws_route53_zone.website.zone_id
  name    = "www.rekoglabelify.com"
  type    = "A"

  alias {
    name                   = var.aws_cloudfront_distribution_domain_name  
    zone_id                = var.aws_cloudfront_distribution_hosted_zone_id 
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in var.aws_acm_certificate_website : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.website.zone_id
}


# Certificate validation
resource "aws_acm_certificate_validation" "website" {
  provider                = aws.us_east_1
  certificate_arn         = var.aws_acm_certificate_website_arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}