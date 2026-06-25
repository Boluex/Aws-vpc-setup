output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vera_vpc.id
}

output "bastion_instance_id" {
  description = "The ID of the Bastion instance"
  value       = aws_instance.bastion_instance.id
}

output "bastion_public_ip" {
  description = "The public IP address of the Bastion instance"
  value       = aws_instance.bastion_instance.public_ip
}

output "frontend_instance_id" {
  description = "The ID of the Frontend Web instance"
  value       = aws_instance.frontend_web_instance.id
}

output "frontend_public_ip" {
  description = "The public IP address of the Frontend Web instance"
  value       = aws_instance.frontend_web_instance.public_ip
}

output "backend_instance_id" {
  description = "The ID of the Backend Web instance"
  value       = aws_instance.backend_web_instance.id
}

output "backend_private_ip" {
  description = "The private IP address of the Backend Web instance"
  value       = aws_instance.backend_web_instance.private_ip
}

output "database_instance_id" {
  description = "The ID of the Database instance"
  value       = aws_instance.database_instance.id
}

output "database_private_ip" {
  description = "The private IP address of the Database instance"
  value       = aws_instance.database_instance.private_ip
}
