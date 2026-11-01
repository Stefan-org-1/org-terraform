# org-terraform

Applies [org-manifest](https://github.com/Stefan-org-1/org-manifest) and [org-policy](https://github.com/Stefan-org-1/org-policy) to GitHub: repos, teams and members, team access, rulesets, environments, and the org Actions policy. Platform only.

Removing a repo from the manifest archives it; nothing is deleted.

## Run locally

With `org-manifest` and `org-policy` checked out next to this repo:

```
terraform init
terraform plan
terraform apply
```

It signs in with `GITHUB_TOKEN`, or the `gh` CLI login. State is local for now (`terraform.tfstate`, gitignored).

Two things are set by hand, because the provider has no resource for them: the gate App as a protection rule on each environment, and the App itself.
