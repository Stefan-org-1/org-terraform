# org-terraform's own environments. Both hold the org-admin App key and accept runs only from main.
# plan: no approval. apply: after a member of group-org-approvers approves. Admins cannot skip it.

resource "github_repository_environment" "terraform_plan" {
  repository  = github_repository.repo["org-terraform"].name
  environment = "plan"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

# A reviewer team must have access to the repo, or GitHub silently drops it from the environment.
resource "github_team_repository" "org_approvers" {
  team_id    = github_team.group["group-org-approvers"].id
  repository = github_repository.repo["org-terraform"].name
  permission = "pull"
}

resource "github_repository_environment" "terraform_apply" {
  repository  = github_repository.repo["org-terraform"].name
  environment = "apply"

  # Off, so an admin cannot skip approval from the run page. Turning it back on is a settings
  # change that shows in the org audit log.
  can_admins_bypass = false

  # In a real org also set prevent_self_review = true. This lab has one approver.
  reviewers {
    teams = [github_team.group["group-org-approvers"].id]
  }

  depends_on = [github_team_repository.org_approvers]

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
