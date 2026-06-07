<!--
Sync Impact Report
==================
Version Change: 1.1.0 → 1.2.0

Modified Principles:
- III. Git Flow Discipline — expanded to define the full git-flow branch set
  (main, develop, feature/*, bugfix/*, release/*, hotfix/*)

Added Sections:
- Principle VII: Simplicity (KISS, DRY, YAGNI)
- Principle VIII: Documentation & Architecture Decision Records (ADR)
- Principle IX: Explicit Error Handling (No Silent Fallbacks)

Updated Sections:
- Code Review & Quality Gates: added ADR + simplicity + fail-loud checks to PR checklist

Removed Sections: None

Templates Requiring Updates:
✅ .specify/templates/tasks-template.md - Updated: added ADR task to Polish phase
✅ .specify/templates/plan-template.md - reviewed, Constitution Check section is generic and compatible
✅ .specify/templates/spec-template.md - reviewed, no changes required
✅ AGENTS.md - reviewed, git-flow / docs conventions consistent

Follow-up TODOs:
- docs/ and docs/adr/ directories do not yet exist; create docs/adr/README.md when the first ADR is written.
-->

# Radvent Constitution

## Core Principles

### I. Test Coverage Quality
RSpec testing is mandatory with SimpleCov coverage reporting. All features MUST include appropriate test
coverage before merging. Coverage reports generated to `coverage/` directory after each test run. Tests
MUST be written for models, controllers, and critical business logic. Coverage MUST NOT regress without
explicit justification and approval.

**Rationale**: Automated tests catch regressions early and document expected behavior. Coverage tracking
ensures quality remains high as the codebase grows.

### II. Rails Best Practices
All Ruby/Rails code MUST follow the conventions defined in AGENTS.md: single quotes by default,
HAML-only views (never ERB), proper ActiveRecord validations, standard controller patterns with
`before_action`, and correct routing patterns. Event routing uses name not ID
(`show_event_path(event.name)`). Model relationships MUST use standard associations and callbacks only
where necessary.

**Rationale**: Consistent conventions improve code readability, reduce bugs, and enable efficient
onboarding. Following Rails conventions leverages framework wisdom.

### III. Git Flow Discipline
The git-flow branching model MUST be followed. The branch set is fixed:

- `main`: production-ready, released code only.
- `develop`: integration branch for the next release.
- `feature/*`: new features, branched from and merged back into `develop`.
- `bugfix/*`: non-urgent fixes, branched from and merged back into `develop`.
- `release/*`: release stabilization, branched from `develop`, merged into both `main` and `develop`.
- `hotfix/*`: urgent production fixes, branched from `main`, merged into both `main` and `develop`.

Direct commits to `main` or `develop` are PROHIBITED. Explicit user permission is REQUIRED before ANY
commit, push, or PR creation. Git operations MUST wait for user approval and user-provided commit
messages.

**Rationale**: Branching discipline prevents accidental production code changes and gives every change a
clear path to production. Explicit approval ensures the user maintains control over commits and
deployment decisions.

### IV. Internationalization
All user-facing strings MUST use i18n with `t()` helper methods. Default locale is Japanese (`:ja`)
with English support. Timezone is Tokyo. Locale auto-detection via `http_accept_language` gem.
Hardcoded strings in views are prohibited.

**Rationale**: Consistent i18n supports multi-language deployment and makes localization tractable.
Avoids hard-to-maintain scattered translations.

### V. Code Consistency
Ruby code MUST be formatted using rufo (single quotes configured). Naming conventions: Models
(Singular/PascalCase), Controllers (Plural/PascalCase), Tables (Plural/snake_case), Views
(controller/action.haml), Private methods (snake_case). File attachments use CarrierWave. Asset
builds use esbuild and SCSS with Bootstrap 5/mdb-ui-kit.

**Rationale**: Automated formatting eliminates style debates. Consistent naming makes navigation
intuitive and reduces cognitive load.

### VI. Test-Driven Development (TDD)
All implementation work MUST follow the Red-Green-Refactor cycle:

1. **Red**: Write a failing RSpec test that defines the expected behavior first.
2. **Green**: Write the minimum production code needed to make the test pass.
3. **Refactor**: Improve code quality while keeping all tests green.

No implementation code MUST be committed without a corresponding failing test written first. New
features, bug fixes, and behavior changes all MUST begin with a failing test. Skipping the Red phase
(writing tests after implementation) is prohibited. Tests MUST be verified to fail before proceeding
to the Green phase.

**Rationale**: TDD ensures tests document intended behavior before implementation, prevents
over-engineering, and guarantees test coverage for all new code by design. It also serves as a design
tool, encouraging smaller and more focused units of code.

### VII. Simplicity (KISS, DRY, YAGNI)
Code and design MUST favor simplicity:

- **KISS** (Keep It Simple, Stupid): Prefer the simplest solution that satisfies the requirement.
  Avoid clever or speculative complexity.
- **DRY** (Don't Repeat Yourself): Extract shared logic instead of duplicating it. Knowledge MUST have
  a single, authoritative representation.
- **YAGNI** (You Aren't Gonna Need It): Implement only what current requirements demand. Do NOT build
  features, abstractions, or configuration for anticipated future needs.

Any complexity beyond the simplest viable approach MUST be justified with concrete, present-day
reasoning (see Complexity Tracking in the plan template).

**Rationale**: Simpler code is easier to read, test, and change. Premature abstraction and duplication
are leading sources of defects and maintenance cost.

### VIII. Documentation & Architecture Decision Records (ADR)
Project documentation lives under `docs/`. Before implementing, the relevant documents under `docs/`
MUST be consulted; identify them by filename. When adding documentation, the filename MUST clearly
describe its contents.

Significant design decisions MUST be recorded as ADRs under `docs/adr/`:

- An ADR MUST be written whenever an important architectural or design decision is made. When unsure
  whether a decision warrants an ADR, ASK the user.
- ADRs are **append-only**: once written, existing ADR content MUST NOT be modified. Superseding a
  decision is done by adding a new ADR that references the old one.
- `docs/adr/README.md` MUST list and link every ADR document, kept up to date as ADRs are added.

**Rationale**: A discoverable, well-named documentation set plus an immutable decision log preserves the
reasoning behind the system, prevents repeated debates, and lets new contributors understand *why*, not
just *what*.

### IX. Explicit Error Handling (No Silent Fallbacks)
Errors MUST be treated as errors. Convenient fallbacks that mask failures are PROHIBITED:

- Do NOT swallow exceptions or substitute default/placeholder values to keep execution going when an
  operation has genuinely failed.
- Do NOT silently catch-and-continue. Failures MUST surface — raise, return an explicit error, or fail
  the request — so the problem is visible.
- Fallback behavior is permitted ONLY when it is a deliberate, documented part of the design, not a
  shortcut to avoid handling an error.

**Rationale**: Silent fallbacks hide bugs, corrupt data, and turn simple failures into hard-to-diagnose
incidents. Loud, explicit failures keep the system honest and debuggable.

## Security & Access Control

Devise authentication is REQUIRED for user access. Admin actions protected with `admin_user!` helper.
Authorization checks via `before_action :authenticate_user!`. Error handling uses `render_404` and
`render_403` helpers. Validation errors use standard Rails patterns with i18n keys. Database
credentials MUST use environment variables (`DB`, `DB_USERNAME`, `DB_PASSWORD`, etc.). Secret key
MUST be set for production via `SECRET_KEY_BASE`.

Sensitive data like passwords and API keys MUST never be logged or committed. File uploads use
CarrierWave with proper validation. Comment model stores `user_name` string only (no `user_id`
relationship to User model).

**Rationale**: Security is non-negotiable. Proper authentication, authorization, and credential
management prevent unauthorized access and data exposure.

## Code Review & Quality Gates

All code changes MUST pass: RSpec test suite (`bundle exec rspec spec`), rufo formatting
(`rufo app/ spec/ lib/`), and lint checks. Test coverage MUST NOT decrease. Code MUST follow patterns
in AGENTS.md. Database migrations MUST be tested and reversible. Asset precompilation required for
production (`bundle exec rake assets:precompile RAILS_ENV=production`).

Before creating a PR, verify: Tests pass locally, Code is formatted per rufo, New functionality has
test coverage written via TDD (failing tests written before implementation code), Code follows KISS/
DRY/YAGNI (no unjustified complexity or duplication), Significant design decisions are captured as
append-only ADRs under `docs/adr/` (and linked from `docs/adr/README.md`), No silent fallbacks mask
failures, Database migrations are safe, No hardcoded secrets or credentials.

**Rationale**: Quality gates prevent broken code from reaching production. Automated checks catch
common issues early.

## Governance

This constitution supersedes all other practices and MUST be referenced during all development
activities. Amendments require: Documentation of proposed changes, explicit approval from project
maintainer, and migration plan for any non-backward-compatible changes. All PRs and reviews MUST
verify compliance with these principles. Complexity beyond these standards MUST be justified with
clear reasoning.

For runtime development guidance, refer to AGENTS.md which contains detailed conventions, Git Flow
procedures, and project-specific gotchas. AGENTS.md is the authoritative reference for implementation
details and should be consulted before making changes.

**Version**: 1.2.0 | **Ratified**: 2026-02-27 | **Last Amended**: 2026-06-06
