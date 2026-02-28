<!--
Sync Impact Report
==================
Version Change: [NEW] → 1.0.0 (initial ratification)

Modified Principles: N/A (initial version)

Added Sections:
- Core Principles (5 principles)
- Security & Access Control
- Code Review & Quality Gates

Removed Sections: N/A

Templates Requiring Updates:
✅ .specify/templates/plan-template.md - reviewed, Constitution Check section compatible
✅ .specify/templates/spec-template.md - reviewed, requirements format compatible
✅ .specify/templates/tasks-template.md - reviewed, task organization compatible
✅ AGENTS.md - referenced for runtime guidance

Follow-up TODOs: N/A
-->

# Radvent Constitution

## Core Principles

### I. Test Coverage Quality
RSpec testing is mandatory with SimpleCov coverage reporting. All features MUST include appropriate test coverage before merging. Coverage reports generated to `coverage/` directory after each test run. Tests MUST be written for models, controllers, and critical business logic. Coverage should not regress without explicit justification and approval.

**Rationale**: Automated tests catch regressions early and document expected behavior. Coverage tracking ensures quality remains high as the codebase grows.

### II. Rails Best Practices
All Ruby/Rails code MUST follow the conventions defined in AGENTS.md: single quotes by default, HAML-only views (never ERB), proper ActiveRecord validations, standard controller patterns with `before_action`, and correct routing patterns. Event routing uses name not ID (`show_event_path(event.name)`). Model relationships MUST use standard associations and callbacks only where necessary.

**Rationale**: Consistent conventions improve code readability, reduce bugs, and enable efficient onboarding. Following Rails conventions leverages framework wisdom.

### III. Git Flow Discipline
Strict Git Flow branching model MUST be followed: `feature/*` and `bugfix/*` branches from `develop`, NEVER commit directly to `main` or `develop`. PRs MUST go from feature branch to `develop`. Explicit user permission REQUIRED before ANY commit, push, or PR creation. Git operations MUST wait for user approval and user-provided commit messages.

**Rationale**: Branching discipline prevents accidental production code changes. Explicit approval ensures user maintains control over commits and deployment decisions.

### IV. Internationalization
All user-facing strings MUST use i18n with `t()` helper methods. Default locale is Japanese (`:ja`) with English support. Timezone is Tokyo. Locale auto-detection via `http_accept_language` gem. Hardcoded strings in views are prohibited.

**Rationale**: Consistent i18n supports multi-language deployment and makes localization tractable. Avoids hard-to-maintain scattered translations.

### V. Code Consistency
Ruby code MUST be formatted using rufo (single quotes configured). Naming conventions: Models (Singular/PascalCase), Controllers (Plural/PascalCase), Tables (Plural/snake_case), Views (controller/action.haml), Private methods (snake_case). File attachments use CarrierWave. Asset builds use esbuild and SCSS with Bootstrap 5/mdb-ui-kit.

**Rationale**: Automated formatting eliminates style debates. Consistent naming makes navigation intuitive and reduces cognitive load.

## Security & Access Control

Devise authentication is REQUIRED for user access. Admin actions protected with `admin_user!` helper. Authorization checks via `before_action :authenticate_user!`. Error handling uses `render_404` and `render_403` helpers. Validation errors use standard Rails patterns with i18n keys. Database credentials MUST use environment variables (`DB`, `DB_USERNAME`, `DB_PASSWORD`, etc.). Secret key MUST be set for production via `SECRET_KEY_BASE`.

Sensitive data like passwords and API keys MUST never be logged or committed. File uploads use CarrierWave with proper validation. Comment model stores `user_name` string only (no `user_id` relationship to User model).

**Rationale**: Security is non-negotiable. Proper authentication, authorization, and credential management prevent unauthorized access and data exposure.

## Code Review & Quality Gates

All code changes MUST pass: RSpec test suite (`bundle exec rspec spec`), rufo formatting (`rufo app/ spec/ lib/`), and lint checks. Test coverage should not decrease. Code MUST follow patterns in AGENTS.md. Database migrations MUST be tested and reversible. Asset precompilation required for production (`bundle exec rake assets:precompile RAILS_ENV=production`).

Before creating a PR, verify: Tests pass locally, Code is formatted per rufo, New functionality has test coverage, Database migrations are safe, No hardcoded secrets or credentials.

**Rationale**: Quality gates prevent broken code from reaching production. Automated checks catch common issues early.

## Governance

This constitution supersedes all other practices and MUST be referenced during all development activities. Amendments require: Documentation of proposed changes, explicit approval from project maintainer, and migration plan for any non-backward-compatible changes. All PRs and reviews MUST verify compliance with these principles. Complexity beyond these standards MUST be justified with clear reasoning.

For runtime development guidance, refer to AGENTS.md which contains detailed conventions, Git Flow procedures, and project-specific gotchas. AGENTS.md is the authoritative reference for implementation details and should be consulted before making changes.

**Version**: 1.0.0 | **Ratified**: 2026-02-27 | **Last Amended**: 2026-02-27
