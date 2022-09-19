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
  name     = "go.local"
  password = data.vault_generic_secret.this.data["password"]
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = data.terraform_remote_state.aws-core.outputs.vpc_id
    subnet_ids = [
			data.terraform_remote_state.aws-core.outputs.public_subnets
			]
  }
}

data "vault_generic_secret" "this" {
	path = "secrets/aws_active_directory"
}
