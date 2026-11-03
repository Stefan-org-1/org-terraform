# Deploys log in to Azure with GitHub's OIDC token, not a stored secret.
# Azure trusts a token only if its subject names the repo, the environment and the central
# deploy template, so a job the team writes into its own workflow is refused.

# Changes the subject of every OIDC token in the org, from
#   repo:ORG/REPO:environment:ENV
# to
#   repo:ORG/REPO:environment:ENV:job_workflow_ref:ORG/ci-templates/.github/workflows/deploy.yml@refs/tags/deploy-v2
# Every Azure trust rule must use the new form.
resource "github_actions_organization_oidc_subject_claim_customization_template" "org" {
  include_claim_keys = ["repo", "context", "job_workflow_ref"]
}

# Identities created by hand in the portal for now. Moves here when the Azure side is Terraform.
locals {
  azure = {
    tenant_id       = "af31b44c-a3bc-41e8-97d1-a310e2682b4c"
    subscription_id = "0b2554ee-3474-4234-b903-70aa1a8d6ce8"
    environments = {
      "payments-web:prod" = {
        client_id      = "4ee51823-2b83-4207-a484-78ad17db16a1" # id-payments-web-prod
        resource_group = "rg-payments-web-prod"
      }
    }
  }

  # Not secrets: they identify, they grant nothing. The trust rule in Azure is the control.
  azure_variables = merge([
    for key, e in local.azure.environments : {
      "${key}:AZURE_TENANT_ID"       = { env = key, name = "AZURE_TENANT_ID", value = local.azure.tenant_id }
      "${key}:AZURE_SUBSCRIPTION_ID" = { env = key, name = "AZURE_SUBSCRIPTION_ID", value = local.azure.subscription_id }
      "${key}:AZURE_CLIENT_ID"       = { env = key, name = "AZURE_CLIENT_ID", value = e.client_id }
      "${key}:AZURE_RESOURCE_GROUP"  = { env = key, name = "AZURE_RESOURCE_GROUP", value = e.resource_group }
    }
  ]...)
}

resource "github_actions_environment_variable" "azure" {
  for_each = local.azure_variables

  repository    = github_repository_environment.env[each.value.env].repository
  environment   = github_repository_environment.env[each.value.env].environment
  variable_name = each.value.name
  value         = each.value.value
}
