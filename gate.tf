locals {
  gate_app_id    = 5543165
  actions_app_id = 15368 # GitHub Actions

  active_repos = { for name, r in local.repos : name => r if r.status == "active" }

  environments = {
    for e in flatten([
      for name, r in local.active_repos : [
        for env in keys(lookup(lookup(r, "rulesets", {}), "deploy", {})) : { repo = name, env = env }
      ]
    ]) : "${e.repo}:${e.env}" => e
  }
}

resource "github_repository_ruleset" "baseline" {
  for_each = local.active_repos

  name        = "platform-baseline"
  repository  = github_repository.repo[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # Org admins can bypass: the merge-side break-glass for this lab.
  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    deletion         = true
    non_fast_forward = true

    required_status_checks {
      # Only a check from the gate App counts.
      required_check {
        context        = "policy"
        integration_id = local.gate_app_id
      }

      # Extra checks a repo requires, from GitHub Actions.
      dynamic "required_check" {
        for_each = lookup(each.value, "required_checks", [])
        content {
          context        = required_check.value
          integration_id = local.actions_app_id
        }
      }
    }

    # Opt in per repo with code_owner_review: true. GitHub then enforces CODEOWNERS on PRs.
    dynamic "pull_request" {
      for_each = lookup(each.value, "code_owner_review", false) ? [1] : []
      content {
        required_approving_review_count   = 1
        require_code_owner_review         = true
        dismiss_stale_reviews_on_push     = true
        require_last_push_approval        = true
        required_review_thread_resolution = false
      }
    }
  }
}

resource "github_repository_environment" "env" {
  for_each = local.environments

  repository  = github_repository.repo[each.value.repo].name
  environment = each.value.env
}

# Release tags are immutable: once X.Y.Z exists, nobody but an org admin can move or delete it.
# Creating one is open to anyone with write access; release.yml is the paved road.
resource "github_repository_ruleset" "release_tags" {
  for_each = local.active_repos

  name        = "release-tags"
  repository  = github_repository.repo[each.key].name
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/tags/*.*.*"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    update   = true
    deletion = true
  }
}
