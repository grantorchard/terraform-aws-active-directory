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
  #edition  = "Standard"
  type     = "SimpleAD"

  vpc_settings {
    vpc_id     = data.terraform_remote_state.aws-core.outputs.vpc_id
    subnet_ids = slice(data.terraform_remote_state.aws-core.outputs.public_subnets, 0, 2)
  }
}

data "vault_generic_secret" "this" {
	path = "secrets/aws_active_directory"
}



module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.1.4"

	ami = "ami-085cd86733cd29a21"
	key_name = "go"

	subnet_id = data.terraform_remote_state.aws-core.outputs.public_subnets[0]
}


