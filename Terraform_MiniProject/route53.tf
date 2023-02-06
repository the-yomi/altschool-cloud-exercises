
variable "domainname" {
    default = "yomiadebowale.me"
    type = string
}


resource "aws_route53_zone" "hostedzone" {
    name = var.domainname

    tags = { 
        Environment = "dev"
    }
}

resource "aws_route53_record" "sitedomain" {
    zone_id = aws_route53_zone.hostedzone.zone_id
    name = "terraform-test.${var.domainname}"
    type = "A"

    alias {
        name = aws_lb.t_loadbalancer.dns_name
        zone_id = aws_lb.t_loadbalancer.zone_id
        evaluate_target_health = true
    }
}