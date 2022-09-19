output "endpoint" {
	value = aws_directory_service_directory.this.access_url
}

# output "password" {
# 	value = module.ec2-instance.password_data
# }
