resource "github_actions_organization_permissions" "org" {
  lifecycle {
    prevent_destroy = true

    # A wrong path or a broken checkout makes the manifest look empty, and Terraform would then
    # plan to remove every repo, team and member. Refuse to plan instead.
    precondition {
      condition     = length(local.team_files) > 0 && contains(keys(local.repos), "org-terraform")
      error_message = "The manifest loaded no team files, or not the platform repos. Check manifest_dir (${local.manifest})."
    }
  }

  enabled_repositories = "all"
  allowed_actions      = "selected"
  sha_pinning_required = true

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = false
    patterns_allowed     = yamldecode(file("${local.policy}/actions-allowlist.yaml")).patterns
  }
}
