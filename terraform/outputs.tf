output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.devops.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group."
  value       = aws_autoscaling_group.devops.arn
}

output "launch_template_id" {
  description = "Launch Template ID."
  value       = aws_launch_template.devops.id
}
