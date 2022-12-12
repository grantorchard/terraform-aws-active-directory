output "dns_servers" {
	value = aws_directory_service_directory.this.dns_ip_addresses
}

output "windows_ip" {
	value = aws_instance.this.public_ip
}
