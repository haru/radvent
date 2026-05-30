# Copilot Instructions for Radvent

> Full conventions, architecture, and gotchas are documented in [AGENTS.md](../AGENTS.md). Read it before making changes.

## Critical Rules

- **Never commit/push** without explicit user permission
- **Always run lint** after code changes: `sh build-scripts/lint.sh`
- **TDD**: Write failing tests first, then implement (90%+ coverage required)
- **Views**: HAML only (`.html.haml`) — never ERB
- **JS**: Stimulus only — never jQuery
- **Migrations**: Generate with `rails generate migration`, never write by hand

## Quick Reference

| Task | Command |
|------|---------|
| Run all tests | `bundle exec rspec spec` |
| Lint | `sh build-scripts/lint.sh` |
| Setup DB | `bundle exec rake db:create db:migrate` |
| Build assets | `yarn build && yarn build:css` |

## Key Gotchas

- `render_not_found` / `render_forbidden` — not `render_404`/`render_403`
- Events routed by `name`, not `id`: `show_event_path(event.name)`
- Boards routed by `board_id` (slug): `board_path(board.board_id)`
- `AdventCalendarItem.date` is Integer (1–31), not a Date
- `Comment` has no `user_id` — stores `user_name` string only

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
