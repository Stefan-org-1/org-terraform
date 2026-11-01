# org-terraform

Applies [org-manifest](https://github.com/Stefan-org-1/org-manifest) and [org-policy](https://github.com/Stefan-org-1/org-policy) to GitHub: repos, teams and members, team access, rulesets, environments, and the org Actions policy. Platform only.

Removing a repo from the manifest archives it; nothing is deleted.

## How changes are applied

The `reconcile` workflow runs every hour, on pushes here, and on demand (**Actions → reconcile → Run workflow**). It does not run on merges in `org-manifest` or `org-policy`, so nothing there needs a secret. Run it by hand after merging there, or wait for the hour.

1. **Plan** (environment `plan`, read-only App token): checks out the latest `main` of all three repos, plans, and writes a summary to the run: changes by kind, destroys and replaces first and flagged, and links to what was merged in each repo since the last apply.
2. **Apply** (environment `apply`): waits for a `team-platform` member to approve it with **Review deployments**, then applies exactly the saved plan, from the same commits. If the state changed since, Terraform refuses the stale plan and the next run plans again.

Only one run is in flight at a time (concurrency group `terraform`), and HCP Terraform locks the state. A plan with no resource changes skips the apply.

The `org-admin` App holds the rights. Its key is only in the `plan` and `apply` environments, which accept runs from `main` only.

## Run locally

With `org-manifest` and `org-policy` checked out next to this repo:

```
terraform init
terraform plan
terraform apply
```

It signs in to GitHub with `GITHUB_TOKEN`, or the `gh` CLI login. State is stored and locked in HCP Terraform (organization `stefan-terraform-test`, workspace `test-terraform`); run `terraform login` once to reach it.

Two things are set by hand, because the provider has no resource for them: the gate App as a protection rule on each environment, and the App itself.
