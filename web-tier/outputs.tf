output "lb" {
  value = {
    dns_name = aws_lb.webtier_lb.dns_name
    zone_id  = aws_lb.webtier_lb.zone_id
  }
}
