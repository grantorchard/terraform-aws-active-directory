locals {
	vpc_id = data.terraform_remote_state.aws-core.outputs.vpc_id
}

data "terraform_remote_state" "aws-core" {
  backend = "remote"

  config = {
    organization = "grantorchard"
    workspaces = {
      name = "aws-core"
    }
  }
}

resource "aws_directory_service_directory" "this" {
  name     = "gcve.local"
  password = data.vault_generic_secret.this.data["password"]
  #edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = local.vpc_id
    subnet_ids = slice(data.terraform_remote_state.aws-core.outputs.public_subnets, 0, 2)
  }
}

data "vault_generic_secret" "this" {
	path = "secrets/aws_active_directory"
}

# module "ec2-instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "4.1.4"

# 	ami = "ami-085cd86733cd29a21"
# 	key_name = "go-rsa"

# 	name = "ad_manager"
# 	subnet_id = data.terraform_remote_state.aws-core.outputs.public_subnets[0]
# }

resource "aws_security_group" "rdp_ingress" {
	name        = "simplead_rdp_ingress"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "permit_rdp_ingress" {
  protocol          = "tcp"
  security_group_id = aws_security_group.rdp_ingress.id
	cidr_blocks       = [
		"27.32.248.192/32",
		"180.150.37.27/32"
	]
  from_port         = 3389
  to_port           = 3389
  type              = "ingress"
}

resource "aws_security_group" "egress" {
	name        = "egress"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "permit_egress" {
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
	security_group_id = aws_security_group.egress.id
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_instance" "this" {
	ami = "ami-047d774cd780e511f"
	instance_type = "t3.micro"
	key_name = "go-rsa"
	tags = {
		Name = "ad-stuff"
	}
	subnet_id = data.terraform_remote_state.aws-core.outputs.public_subnets[0]
	security_groups = [
		aws_security_group.rdp_ingress.id,
		aws_security_group.egress.id
	]
	associate_public_ip_address = true
	ignore_changes = [
		vpc_security_group_ids
	]
}

# vault write pki_int/intermediate/generate/internal common_name="vault.gcve.local Intermediate Authority" ttl=43800h