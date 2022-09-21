output "dns_servers" {
	value = aws_directory_service_directory.this.dns_ip_addresses
}
