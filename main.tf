locals {
	vpc_id = data.terraform_remote_state.aws-core.outputs.vpc_id
  workspace_secret_path = "${data.tfe_workspace.self.project_id}/${data.tfe_workspace.self.id}"
}

data "terraform_remote_state" "aws-core" {
  backend = "remote"

  config = {
    organization = var.tfc_organisation
    workspaces = {
      name = "aws-core"
    }
  }
}

data "tfe_workspace" "self" {
  organization = var.tfc_organisation
  name = var.TFC_WORKSPACE_NAME
}

resource "aws_directory_service_directory" "this" {
  name     = "gcve.local"
  password = data.vault_generic_secret.this.data["password"]

  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = local.vpc_id
    subnet_ids = slice(data.terraform_remote_state.aws-core.outputs.public_subnets, 0, 2)
  }
}

data "vault_generic_secret" "this" {
	path = "secrets/${local.workspace_secret_path}/aws_active_directory"
}

resource "aws_security_group" "rdp_ingress" {
	name        = "ad_client_ingress"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "permit_rdp_ingress" {
  protocol          = "tcp"
  security_group_id = aws_security_group.rdp_ingress.id
	cidr_blocks       = [
		"27.32.248.192/32",
	]
  from_port         = 3389
  to_port           = 3389
  type              = "ingress"
}

# resource "aws_security_group_rule" "permit_https_ingress" {
#   protocol          = "tcp"
#   security_group_id = aws_security_group.rdp_ingress.id
# 	cidr_blocks       = [
# 		"27.32.248.192/32",
# 		"180.150.37.27/32"
# 	]
#   from_port         = 443
#   to_port           = 443
#   type              = "ingress"
# }

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
	ami = "ami-039965e18092d85cb"
	instance_type = "t3.small"
	key_name = "go-rsa"
  iam_instance_profile = "domain_join"
	tags = {
		Name = "ad-stuff"
	}
	subnet_id = data.terraform_remote_state.aws-core.outputs.public_subnets[0]
	security_groups = [
		aws_security_group.rdp_ingress.id,
    aws_security_group.egress.id
	]
	associate_public_ip_address = true
	lifecycle {
		ignore_changes = [
			vpc_security_group_ids,
			security_groups
		]
	}
}