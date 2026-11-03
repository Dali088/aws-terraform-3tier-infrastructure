output "alb_dns_name" {
  description = "Public DNS name of the load balancer. Open http://<this> in a browser."
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group, used to check instance health from the CLI."
  value       = aws_lb_target_group.app.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group, used to find its instances."
  value       = aws_autoscaling_group.app.name
}
