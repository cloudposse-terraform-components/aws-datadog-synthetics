terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9.0, < 6.0.0"
    }
    datadog = {
      source  = "datadog/datadog"
      version = ">= 3.3.0"
    }
    null = {
      source = "hashicorp/null"
      version = ">= 3.2.4"
    }
  }
}
