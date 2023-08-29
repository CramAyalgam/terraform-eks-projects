# resource "aws_acm_certificate" "main" {
#   domain_name               = var.domain_name
#   subject_alternative_names = var.subject_alternative_names
#   validation_method         = "DNS"
# }

# data "aws_route53_zone" "main" {
#   name         = var.domain_name
#   private_zone = false
# }

# resource "aws_route53_record" "validation" {
#   count = length(aws_acm_certificate.main.domain_validation_options)

#   zone_id = data.aws_route53_zone.main.zone_id  # Change to your Route 53 zone ID
#   name    = element(aws_acm_certificate.main.domain_validation_options.*.resource_record_name, count.index)
#   type    = element(aws_acm_certificate.main.domain_validation_options.*.resource_record_type, count.index)
#   records = [element(aws_acm_certificate.main.domain_validation_options.*.resource_record_value, count.index)]
#   ttl     = 300
# }

# # resource "aws_route53_record" "example" {
# #   for_each = {
# #     for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
# #       name    = dvo.resource_record_name
# #       record  = dvo.resource_record_value
# #       type    = dvo.resource_record_type
# #       zone_id = data.aws_route53_zone.example_com.zone_id
# #     }
# #   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = each.value.zone_id
# }

# resource "aws_acm_certificate_validation" "example" {
#   certificate_arn         = aws_acm_certificate.example.arn
#   validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
# }

# # resource "aws_lb_listener" "example" {
# #   # ... other configuration ...

# #   certificate_arn = aws_acm_certificate_validation.example.certificate_arn
# # }



