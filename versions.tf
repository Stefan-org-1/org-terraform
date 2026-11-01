terraform {
  required_version = ">= 1.7"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

# Token comes from GITHUB_TOKEN.
provider "github" {
  owner = "Stefan-org-1"
}

variable "manifest_dir" {
  description = "Checkout of org-manifest"
  type        = string
  default     = "../org-manifest"
}

variable "policy_dir" {
  description = "Checkout of org-policy"
  type        = string
  default     = "../org-policy"
}

locals {
  manifest = "${path.module}/${var.manifest_dir}"
  policy   = "${path.module}/${var.policy_dir}"
}
