---
name: "commit"
description: "Survey the outstanding changes, run lint, and prepare a Conventional-Commits-style message (feat:, fix:, refactor:, docs:, test:, chore:, perf:, ci:) for the user to approve before creating a git commit. Use whenever the user asks to commit, save, or check in their work."
argument-hint: "Optional: additional context about what changed, or which files to include"
compatibility: "Requires a git repository and (for the lint step) build-scripts/lint.sh"
metadata:
  author: "radvent"
  source: "skill-create"
user-invocable: true
disable-model-invocation: false
---

# Commit

Prepare a single git commit for the outstanding changes, but **never commit
without the user's explicit go-ahead on both the action and the message.**

> ⚠️ Per this project's ABSOLUTE RULES in [CLAUDE.md](../../../CLAUDE.md):
> - Do **not** run `git commit` until the user has explicitly approved.
> - Do **not** pick the commit message yourself and commit with it — propose
>   it, then let the user confirm or rewrite it before you commit.
> - Never run `git push` or create a PR from this skill.

## User Input

```text
$ARGUMENTS
```

Consider any additional context from the user input (e.g. "only commit the
tool changes", "this is a bug fix") before proceeding.

## Procedure

### Step 1: Survey the changes

Run in parallel:
- `git status` — see tracked and untracked files
- `git diff` and `git diff --staged` — see the actual content changes
- `git log --oneline -10` — match the repository's existing commit message tone

### Step 2: Run lint

CLAUDE.md requires lint to pass after any code change, before considering work
done. If the diff touches code (not just docs/config), run:

```bash
sh build-scripts/lint.sh
```

If it fails, fix the issues (or report them to the user) before proposing a
commit — do not propose committing code that fails lint.

### Step 3: Stage the changes

Stage the modified and new files that belong to this piece of work
(`git add <files>`, or `git add -A` when everything in the working tree is
part of the same change).

Before proposing a commit, look at the staged file list once more:
- If anything looks like a secret or credential (`.env`, `*.pem`,
  `credentials.json`, API keys, etc.), unstage it and warn the user instead
  of committing it silently.
- If some staged files clearly belong to unrelated, separate work (not what
  the user is asking to commit right now), leave them out and mention it to
  the user.

### Step 4: Determine the commit type

Look at the diff and classify the change into a prefix, per
[git-workflow.md](../../rules/git-workflow.md):

| Prefix      | When to use |
|-------------|-------------|
| `feat:`     | New feature or capability |
| `fix:`      | Bug fix |
| `refactor:` | Restructuring without behavior change |
| `docs:`     | Documentation only |
| `test:`     | Test-only changes |
| `chore:`    | Tooling, dependencies, config, housekeeping |
| `perf:`     | Performance improvement |
| `ci:`       | CI/CD pipeline changes |

If a change spans multiple categories, pick the one that reflects the primary
intent.

### Step 5: Draft the commit message — do not commit yet

Format:
- **Line 1**: `<type>: <description>` — English, imperative mood, no
  trailing period.
- **If the change is small** (one focused fix, a single file, a short diff):
  stop at line 1. No body needed.
- **If the change touches several things**: leave a blank line after line 1,
  then a short optional body explaining context, or a bullet list for
  distinct sub-changes.

Example (small change):
```
fix: correct nil check in issue summary cache lookup
```

Example (larger change):
```
feat: add vector model profile support to settings

- add use_vector_model_profile and vector_model_profile_id columns
- update settings UI to select a dedicated vector model profile
- fall back to the default model profile when unset
```

Do not add a `Co-Authored-By` line or any other reference to Claude/AI
assistance.

**Present the drafted message to the user and explicitly ask for approval —
or ask them to supply/edit the message themselves — before doing anything
else.** Do not proceed to Step 6 on an assumption of approval.

### Step 6: Commit (only after explicit user approval)

Once the user has approved a message (their own or the drafted one), use a
heredoc so multi-line messages are formatted correctly:

```bash
git commit -m "$(cat <<'EOF'
<type>: <description>

- <detail 1>
- <detail 2>
EOF
)"
```

Always create a new commit — never `--amend` an existing one unless the user
explicitly asks for it.

### Step 7: Confirm

Run `git status` after the commit and report the resulting commit (short
hash + first line) to the user. Do not push.

## Notes

- Never push and never open a PR — this skill only commits locally, and only
  after explicit approval.
- Never use `--no-verify` to skip hooks; if a pre-commit hook fails, fix the
  underlying issue, re-stage, and create a **new** commit rather than
  amending (the failed commit never happened).
- Write commit messages in plain English regardless of the conversation
  language.

## Error Handling

- If there is nothing staged and nothing to stage (clean working tree), tell
  the user there is nothing to commit — do not create an empty commit.
- If secrets or clearly unrelated files are detected among the changes, stop
  and confirm with the user before including them.
