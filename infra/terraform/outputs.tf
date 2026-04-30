output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.maintenance_tracker_server.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.maintenance_tracker_server.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.maintenance_tracker_sg.id
}
