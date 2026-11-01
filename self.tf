# org-terraform's own environments. Both hold the org-admin App key and accept runs only from main.
# plan: no approval. apply: after a member of group-org-approvers approves.

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

  # Lab only: one person is both the only admin and the only approver, so this is the fallback
  # when approval itself breaks. A real org sets false, so an admin cannot skip approval from
  # the run page, and sets prevent_self_review = true.
  can_admins_bypass = true

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
