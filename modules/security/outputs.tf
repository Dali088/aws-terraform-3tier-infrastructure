output "alb_security_group_id" {
  description = "ID of the load balancer security group, attached to the ALB in Part 3e."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application security group, attached to the instances in Part 3e."
  value       = aws_security_group.app.id
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile, referenced by the launch template in Part 3e."
  value       = aws_iam_instance_profile.app.name
}
