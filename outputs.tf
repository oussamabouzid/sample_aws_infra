output "jumpbox_ip_addr" {
  value       = aws_instance.jumpbox.public_ip
  description = "The public IP address of the main jumpbox instance."
}

output "aws_lb" {
  value       = aws_lb.be-elb.dns_name
  description = "The public DNS of the frontal LoadBalancer"
}

output "private-ips" {
  description = "The private IP addresses of the main jumpbox instance."
  value       = data.aws_instance.asg-instances.*.private_ip
}