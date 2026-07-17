---
name: triage-github-issues
description: Fetches and reads every open GitHub issue for this repo, then reports a triage summary (what each issue asks for, size/complexity, suggested next steps) so the user can decide what to work on. Use when the user asks to check/triage/review the repo's GitHub issues. Does not open PRs, comment, or write code — read-and-report only.
---

## Triage GitHub Issues

Read-only reconnaissance skill: gather every open issue for this repository, read each one in full (including comments), and report back a triage summary. Do not start implementing anything as part of this skill — that's a separate step the user will ask for explicitly afterward.

### Step 1: Identify the repo

Determine the GitHub repo from the working directory's git remote:

```
git remote get-url origin
```

Parse the `owner/repo` out of the URL (works for both `https://github.com/owner/repo.git` and `git@github.com:owner/repo.git` forms). If there's no git remote, ask the user which `owner/repo` to use.

### Step 2: List issues

```
gh issue list --repo <owner/repo> --state open --limit 100
```

If the user's request implies including closed issues (e.g. "all issues", "closed too"), add `--state all`.

### Step 3: Read each issue in full

For every issue number returned, fetch full detail including comments — don't rely on the list output, since titles alone hide the actual ask:

```
gh issue view <number> --repo <owner/repo> --comments
```

Do this for all issues before reporting anything. Batch independent `gh issue view` calls together rather than one at a time.

### Step 4: Report a triage summary

For each issue, report back concisely:

- **Number + title**
- **What's actually being asked** (one or two sentences — paraphrase the body, don't just repeat the title)
- **Where in the codebase this likely touches** (a quick, best-effort guess — a file or module name if obvious from context you already have; skip if not obvious, don't go spelunking through the whole codebase for this)
- **Rough size**: trivial / small / medium / large
- **Anything blocking or needing a user decision** (ambiguous requirements, missing info, conflicts with another open issue, etc.)

End with a short recommendation: which issue(s) look like reasonable next steps and why (e.g. quick win, blocks other work, most-requested). Do not pick one and start implementing — wait for the user to choose.

If there are zero open issues, just say so plainly instead of padding the report.
