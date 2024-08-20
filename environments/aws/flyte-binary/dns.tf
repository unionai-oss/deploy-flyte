
resource "aws_acm_certificate" "flyte_cert" {
  domain_name       = "flyte.${data.aws_route53_zone.zone.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.flyte_cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.flyte_cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  records = ["${aws_acm_certificate.flyte_cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "dns_validated_cert" {
  certificate_arn         = "${aws_acm_certificate.flyte_cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

resource "aws_route53_record" "elb_record" {

  provisioner "kubectl-get-ingress" {
    command = "export FLYTE_ELB_ADDRESS=$(kubectl get ingress -n flyte -o json | jq -r '.items[].status.loadBalancer.ingress[].ip')"
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.domain_name  # Replace with your desired subdomain
  type    = "A"
  ttl     = 300  # Time to Live in seconds

  records = ["127.0.0.1"] #Once Flyte is deployed, you can change this with the ALB

  allow_overwrite = true

depends_on = [ module.eks, helm_release.flyte-core ]
}
# Change domain_name to match the name you'll use to connect to Flyte


module "external_dns_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.11.2"

  role_name                     = "fthw-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.zone.arn]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

resource "helm_release" "external_dns" {
  namespace = "kube-system"
  wait      = true
  timeout   = 600

  name = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.12.1"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_irsa_role.iam_role_arn
  }
}

output "aws_acm_certificate" {
  value = [aws_acm_certificate.flyte_cert.arn]

}