# The commits of org-manifest, org-policy and org-terraform a run used. Kept in state after each
# apply, so the next plan can list what was merged since.
variable "commits" {
  description = "repo -> commit SHA, set by the reconcile workflow"
  type        = map(string)
  default     = {}
}

output "applied_commits" {
  value = var.commits
}
