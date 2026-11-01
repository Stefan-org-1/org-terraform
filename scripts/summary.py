"""Summarise a saved plan for the person who approves the apply.

usage: summary.py plan.json plan.txt previous_commits.json current_commits.json org

plan.txt is `terraform show` output, included in full so the approver sees each attribute change.

Writes Markdown to stdout, and changes=true|false to $GITHUB_OUTPUT. Only resource changes
count: a plan that only moves the recorded commits needs no apply.
"""

import json
import os
import sys

ORDER = ["delete", "replace", "create", "update"]
FLAG = {"delete": "**destroy**", "replace": "**replace**", "create": "create", "update": "update"}


def kind(actions: list[str]) -> str | None:
    if actions == ["no-op"] or actions == ["read"]:
        return None
    if "delete" in actions and "create" in actions:
        return "replace"
    return actions[0]


def main(plan_path, text_path, previous_path, current_path, org):
    plan = json.load(open(plan_path))
    previous, current = json.load(open(previous_path)), json.load(open(current_path))
    changes = [(k, r["address"]) for r in plan.get("resource_changes", []) if (k := kind(r["change"]["actions"]))]
    changes.sort(key=lambda c: (ORDER.index(c[0]), c[1]))

    out = ["## Terraform plan", ""]
    if not changes:
        out.append("No changes to the org.")
    else:
        counts = {k: sum(1 for c in changes if c[0] == k) for k in ORDER}
        out.append(" · ".join(f"{FLAG[k]}: {n}" for k, n in counts.items() if n))
        if counts["delete"] or counts["replace"]:
            out += ["", "> [!WARNING]", "> This plan destroys or replaces resources. Check each one below before approving."]
        out += ["", "| Action | Resource |", "|---|---|", *(f"| {FLAG[k]} | `{a}` |" for k, a in changes)]
        out += ["", "<details><summary>Full plan: every attribute that changes</summary>", "", "```diff",
                open(text_path).read().rstrip(), "```", "", "</details>"]

    out += ["", "## Merged since the last apply", ""]
    for repo, sha in current.items():
        old = previous.get(repo)
        base = f"https://github.com/{org}/{repo}"
        if old == sha:
            out.append(f"- {repo}: nothing new (`{sha[:7]}`)")
        elif old:
            out.append(f"- {repo}: [{old[:7]}...{sha[:7]}]({base}/compare/{old}...{sha})")
        else:
            out.append(f"- {repo}: [{sha[:7]}]({base}/commit/{sha}) (no earlier apply recorded)")

    print("\n".join(out))
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"changes={'true' if changes else 'false'}\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
