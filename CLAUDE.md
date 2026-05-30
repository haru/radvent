# CLAUDE.md - Claude-specific guidelines for Radvent

> **Primary reference**: Read [AGENTS.md](AGENTS.md) for full project conventions, architecture, commands, and gotchas.
> This file contains only Claude-specific overrides and critical reminders.

## ABSOLUTE RULES (CRITICAL)

**NEVER commit or push changes without explicit user permission**
- Do NOT run `git commit` under any circumstances
- Do NOT run `git push` under any circumstances
- Do NOT create pull requests under any circumstances
- Only show changes with `git diff` after user approves
- Wait for explicit user confirmation before ANY git operations

**NEVER decide commit message without user approval**
- Let user write the commit message
- Do not automatically generate or suggest commit messages
- Ask user for commit message before running `git commit`

**ALWAYS run lint after modifying code**
- After any code change, run `sh build-scripts/lint.sh` and verify it passes
- Do NOT consider a task complete until lint passes

**ALWAYS follow Test-Driven Development (TDD)**
- Write tests BEFORE writing implementation code
- Red → Green → Refactor cycle must be followed strictly
- No production code without a failing test that justifies it
- Run `bundle exec rspec spec` to verify tests pass after implementation
- **Maintain test coverage at 90% or above** — check `coverage/` report after running tests

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
