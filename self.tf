# org-terraform's own environments. Both hold the org-admin App key and accept runs only from main.
# plan: read-only tokens, no approval. apply: write tokens, after a platform member approves.

resource "github_repository_environment" "terraform_plan" {
  repository  = github_repository.repo["org-terraform"].name
  environment = "plan"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment" "terraform_apply" {
  repository  = github_repository.repo["org-terraform"].name
  environment = "apply"

  reviewers {
    teams = [github_team.team["team-platform"].id]
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "terraform_main_only" {
  for_each = {
    plan  = github_repository_environment.terraform_plan.environment
    apply = github_repository_environment.terraform_apply.environment
  }

  repository     = github_repository.repo["org-terraform"].name
  environment    = each.value
  branch_pattern = "main"
}
