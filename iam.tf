data "aws_iam_role" "this" {
  name = "domain_join"
}

resource "aws_ssm_document" "this" {
  name          = "domain_join"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2"
      "description"   = "aws:domainJoin"
      "mainSteps" = [
        {
          "action" = "aws:domainJoin",
          "name"   = "domainJoin",
          "inputs" = {
            "directoryId" : aws_directory_service_directory.this.id,
            "directoryName" : aws_directory_service_directory.this.name
            "dnsIpAddresses" : aws_directory_service_directory.this.dns_ip_addresses
          }
        }
      ]
    }
  )
}

resource "aws_ssm_association" "this" {
  name = aws_ssm_document.this.name
  targets {
    key    = "InstanceIds"
    values = [
        aws_instance.this.id
    ]
  }
}