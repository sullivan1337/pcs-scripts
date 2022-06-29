terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "api_user" {
  type = string
  sensitive = true
}

variable "api_user_passwd" {
  type = string
  sensitive = true
}


# define 2 container definitions, the second definition is pull from a rest api call to the mock server
locals {
  defs = [
    {
      name      = "first"
      image     = "service-first"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
    #add additional container from the module
    jsondecode(data.local_file.test.content)
  ]
}

# create the task definition with the 2 containers
resource "aws_ecs_task_definition" "service-testing" {
  family                = "service-testing"
  container_definitions = jsonencode(local.defs)

  # clean up local file containing the prisma cloud API response after task def is created
  provisioner "local-exec" {
    command = <<EOT
      rm ${path.module}/${null_resource.prisma_api.triggers.filename}
    EOT
  }
}

resource "random_string" "random" {
  length           = 16
  special          = true
  override_special = "@£$"
}

# github reference https://github.com/hashicorp/terraform/issues/20971
# https://discuss.hashicorp.com/t/how-to-retrieve-the-null-resource-returned-value/9620/3
# https://discuss.hashicorp.com/t/using-null-resource-and-external-data-source-together/27120
resource "null_resource" "prisma_api" {
    triggers = {
      # timestamp function here to always trigger the execution of the curl on each apply
      always_run = "${timestamp()}"
      filename = "${path.module}/${random_string.random.result}.json"
    }

  provisioner "local-exec" {
    command = <<EOT
      curl -X POST 'http://127.0.0.1:4545/api/v1/defenders/fargate.json?consoleaddr=northamerica-northeast1.cloud.twistlock.com/canada-550157779&defenderType=appEmbedded' \
           -H 'Content-Type: application/json' \
           -u '${var.api_user}:${var.api_user_passwd}' \
           -d '{"containerDefinitions": "some task" }' > ${self.triggers.filename}
    EOT
  }
}

data "local_file" "test" {
  filename = "${null_resource.prisma_api.triggers.filename}"
}

output "prisma_api_response" {
  value = "${data.local_file.test.content}"
}

