---
name: "create-release-branch"
description: "Create a release/<version> branch from develop, bump the VERSION constant in lib/radvent/version.rb, and prepare (but not run) the version-bump commit for user approval. Use when starting a release or cutting a release branch."
argument-hint: "The release version, e.g. 4.2.0"
compatibility: "Requires a git repository with a develop branch and lib/radvent/version.rb"
metadata:
  author: "radvent"
  source: "skill-create"
user-invocable: true
disable-model-invocation: false
---

# Create Release Branch

Create a `release/<version>` branch from `develop`, bump the `VERSION` constant
in [lib/radvent/version.rb](../../../lib/radvent/version.rb), and prepare the
version-bump commit for the user to approve.

> ⚠️ Per this project's ABSOLUTE RULES in [CLAUDE.md](../../../CLAUDE.md):
> - Creating the branch is a local, reversible action and does not need
>   separate approval, but **do not run `git commit` or `git push` without
>   explicit user approval.**
> - **Never decide the commit message and commit with it** — propose it, then
>   wait for the user to confirm or rewrite it.
> - This skill never pushes and never opens a PR. Once the version-bump
>   commit exists, the `create-pull-request` skill can open the release PR
>   against `main` (see Notes).

## User Input

```text
$ARGUMENTS
```

The user input should contain the target release version (e.g. `4.2.0`). If
no version is provided, ask the user which version to release before
proceeding.

## Procedure

### Step 1: Confirm the current version

Read [lib/radvent/version.rb](../../../lib/radvent/version.rb) and note the
current `VERSION` value:

```bash
grep -oP "VERSION\s*=\s*['\"]\K[^'\"]+" lib/radvent/version.rb
```

Confirm the requested version:
- Follows semantic versioning (`MAJOR.MINOR.PATCH`).
- Is different from (and normally greater than) the current version.

If the requested version is not valid semver, ask the user to confirm before
proceeding.

### Step 2: Check the working tree and for an existing release branch

```bash
git status --short          # working tree should be clean before switching
git branch -a | grep 'release/'
```

- If `release/<version>` already exists (locally or on `origin`), stop and
  report it to the user instead of recreating or overwriting it.
- If the working tree has uncommitted changes unrelated to this task, warn
  the user and confirm how to proceed rather than switching branches over
  them.

### Step 3: Create the release branch

Make sure `develop` is current, then branch from it:

```bash
git fetch origin develop --quiet
git checkout -b release/<version> develop
```

### Step 4: Bump the version

Edit `lib/radvent/version.rb` and update the `VERSION` constant to
`<version>`:

```ruby
module Radvent
  module Version
    VERSION = '<version>'
    # ...
  end
end
```

Keep single-quoted strings (rufo style) and leave the rest of the file
untouched.

### Step 5: Lint

CLAUDE.md requires lint to pass after any code change:

```bash
sh build-scripts/lint.sh
```

Fix any issues before proposing the commit.

### Step 6: Draft the commit — do not commit yet

Stage **only** the version file (do not include unrelated changes such as
`.claude/settings.json` or anything already on the working tree):

```bash
git add lib/radvent/version.rb
```

Draft a Conventional Commits message per
[git-workflow.md](../../rules/git-workflow.md):

```
chore: bump version to <version>
```

**Present this message to the user and explicitly ask for approval — or ask
them to supply/edit it — before running `git commit`.** Do not assume
approval.

### Step 7: Commit (only after explicit user approval)

```bash
git commit -m "$(cat <<'EOF'
chore: bump version to <version>
EOF
)"
```

Do not push. Report the branch name and resulting commit (short hash + first
line) to the user.

## Notes

- Never push and never open a PR from this skill — only branch creation and
  a local commit, and only after explicit approval of the commit itself.
- After this skill, the `create-pull-request` skill can open the release PR
  against `main`. Branch names in this project use the singular
  `release/<version>` form (matching `.github/workflows/auto-tag.yml` and
  `prevent-main-pr.yml`, both of which check `startsWith(..., 'release/')`),
  and `create-pull-request` detects that same `release/*` form.
- Never use `--no-verify` to skip hooks; if a pre-commit hook fails, fix the
  underlying issue, re-stage, and create a **new** commit rather than
  amending.

## Error Handling

- If `lib/radvent/version.rb` is missing or the `VERSION` constant cannot be
  found, stop and report it.
- If `release/<version>` already exists locally or on `origin`, do not
  overwrite it — report the current state and ask how to proceed.
- If the requested version is not valid semver, ask the user to confirm
  before proceeding.
- If the working tree is not clean before branching, warn the user and
  confirm how to proceed.
