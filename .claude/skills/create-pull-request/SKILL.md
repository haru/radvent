---
name: "create-pull-request"
description: "Create a GitHub Pull Request for the current branch. Release branches (releases/*) target main with a version-based title; all other branches target develop with a title and body derived from the spec kit spec.md or the branch diff, plus an appropriate label."
argument-hint: "(no arguments) — run on the branch you want to open a PR for"
compatibility: "Requires gh CLI authenticated, a clone with main/develop branches, and (optionally) spec-kit structure under specs/"
metadata:
  author: "radvent"
  source: "skill-create"
user-invocable: true
disable-model-invocation: false
---

# Create Pull Request

Create a GitHub Pull Request for the **current branch** using the rules below.
The behavior depends on whether the current branch is a release branch.

> 🌐 **The PR title and body MUST be written in English**, even when the source
> material (e.g. `spec.md`, commit messages) is in Japanese. Translate and
> summarize Japanese content into clear English.

> ⚠️ This skill performs `git push` and `gh pr create`, which are outward-facing
> actions. Per the project's ABSOLUTE RULES, **confirm with the user before
> pushing or creating the PR.** Show the computed title, body, base branch, and
> label first, then wait for explicit approval.

## Step 0: Gather context

Run these to determine the situation:

```bash
# Current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Make sure the branch is pushed (needed for gh pr create). Confirm with user first.
# git push -u origin "$CURRENT_BRANCH"
```

Decide the path:

- If `CURRENT_BRANCH` matches `releases/*` → **Release PR path** (Step A).
- Otherwise → **Feature PR path** (Step B).

---

## Step A: Release PR path (branch matches `releases/*`)

**Base branch:** `main`

1. **Get the version** from [lib/radvent/version.rb](lib/radvent/version.rb):

   ```bash
   VERSION=$(ruby -r ./lib/radvent/version -e 'puts Radvent::Version::VERSION' 2>/dev/null \
     || grep -oP "VERSION\s*=\s*['\"]\\K[^'\"]+" lib/radvent/version.rb)
   ```

2. **Title:** `Release <VERSION>` (e.g. `Release 4.0.0`).
3. **Body:** identical to the title — `Release <VERSION>`.
4. **Label:** none.

Create the PR (after user approval):

```bash
gh pr create --base main --head "$CURRENT_BRANCH" \
  --title "Release ${VERSION}" \
  --body "Release ${VERSION}"
```

---

## Step B: Feature PR path (all other branches)

**Base branch:** `develop`

### B1. Find the corresponding spec.md

The spec folder name is the branch name with its `{type}/` prefix stripped
(branch convention is `{type}/{seq}-{kebab}`, folder is `{seq}-{kebab}`).

```bash
# Strip the leading "type/" prefix, e.g. feature/003-image-file-upload -> 003-image-file-upload
SLUG="${CURRENT_BRANCH#*/}"
SPEC_FILE="specs/${SLUG}/spec.md"
# Fallback: .specify/feature.json may point at the active feature directory.
```

If `.specify/feature.json` exists, also check its `feature_directory` value
(`specs/<slug>`) for a `spec.md` as a fallback.

### B2. Determine the title

- **If `spec.md` exists:** summarize its content into a concise title.
  The first heading is typically `# 機能仕様書: <feature name>` — use the feature
  name (the text after the colon), refining it into a short, descriptive PR title.
  Read the spec to capture intent; do not just copy the raw heading verbatim if a
  cleaner summary fits.
- **If `spec.md` does NOT exist:** auto-generate the title from the branch's
  changes. Inspect the diff against `develop` and summarize it:

  ```bash
  git fetch origin develop --quiet
  git log origin/develop..HEAD --oneline
  git diff origin/develop...HEAD --stat
  ```

### B3. Build the body

A short bullet-point summary of what changed on this branch. Derive it from the
commits and diff:

```bash
git log origin/develop..HEAD --pretty=format:'- %s'
git diff origin/develop...HEAD --stat
```

Produce 3–8 bullets **in English** describing the actual changes (not just raw
commit subjects when they're noisy). Example:

```markdown
- Add image file upload button to the article editor toolbar
- Restrict uploads to users with article edit permission
- Show a spinner on the toolbar button while uploading
```

### B4. Choose the label

Classify the change and apply exactly one label:

| Change type      | Label         |
|------------------|---------------|
| New feature / enhancement | `enhancement` |
| Bug fix          | `bug`         |
| Anything else    | `other`       |

Heuristics: branch type prefix (`feature/` → enhancement, `fix/`/`hotfix/` → bug),
commit message types (`feat:` → enhancement, `fix:` → bug), and the spec/diff
content. When unsure, prefer `other`.

> Note: the `other` label may not exist in the repo yet. Create it if missing:
> ```bash
> gh label list --search other --json name -q '.[].name' | grep -qx other \
>   || gh label create other --color ededed --description "Miscellaneous changes"
> ```

### B5. Create the PR (after user approval)

```bash
gh pr create --base develop --head "$CURRENT_BRANCH" \
  --title "<computed title>" \
  --body "<bullet-point body>" \
  --label "<enhancement|bug|other>"
```

---

## Summary of rules

| Current branch | Base | Title | Body | Label |
|----------------|------|-------|------|-------|
| `releases/*`   | `main`    | `Release <version>` (from `lib/radvent/version.rb`) | same as title | none |
| other (spec exists) | `develop` | summary of `specs/<slug>/spec.md` | bullet summary of changes | `enhancement` / `bug` / `other` |
| other (no spec)     | `develop` | auto-generated from branch diff | bullet summary of changes | `enhancement` / `bug` / `other` |

## Notes

- Always present the computed base, title, body, and label to the user and wait
  for explicit approval before `git push` and `gh pr create`.
- If `gh` reports the branch isn't pushed, push it with `git push -u origin <branch>`
  (after approval) and retry.
- If a PR already exists for the branch, report it instead of creating a duplicate
  (`gh pr view`).
