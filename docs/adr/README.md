# Architecture Decision Records

This index lists every ADR in this directory. Entries are append-only — never
remove or rewrite a past entry. A decision that reverses an earlier one gets
a new ADR marked as superseding it; the superseded ADR's file is left
unchanged.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-use-yarn-not-npm.md) | Use Yarn as the sole JS package manager; drop package-lock.json | Accepted |
| [0002](0002-migration-must-self-provision-backfill-dependencies.md) | Migrations must self-provision their backfill dependencies | Accepted |
| [0003](0003-controller-specs-need-render-views-to-catch-view-syntax-errors.md) | Controller specs need render_views to catch view syntax errors | Accepted |
| [0004](0004-separate-theme-endpoint-from-devise-registration.md) | Separate theme endpoint from Devise registration | Accepted |
| [0005](0005-css-theme-switching-via-data-theme-attribute.md) | CSS theme switching via data-theme attribute | Accepted |
| [0006](0006-migrations-must-not-provision-seed-data-via-models.md) | Migrations must not provision seed data via ActiveRecord models | Accepted |
| [0007](0007-serve-new-images-through-authorized-endpoint.md) | Serve new images through an authorized endpoint | Accepted |
| [0008](0008-password-reset-hides-account-existence-and-delivery-failure.md) | Password reset hides account existence and delivery failure | Accepted |
| [0009](0009-address-user-board-events-by-board-and-name.md) | Address user board events by board id and name | Accepted |
| [0010](0010-restrict-slot-info-page-to-author-and-admin.md) | Restrict the slot info page to its author and admins | Accepted |
| [0011](0011-share-auth-rate-limit-counters-in-solid-cache.md) | Share authentication rate-limit counters in Solid Cache | Accepted |
| [0012](0012-account-lockout-is-time-based-and-invisible.md) | Account lockout is time-based, invisible and does not end sessions | Accepted |
| [0013](0013-e2e-tests-with-playwright-and-dedicated-rails-env.md) | E2E tests run with Playwright against a dedicated Rails environment | Accepted |
| [0014](0014-show-user-email-in-board-member-search.md) | Show user email addresses in the board member search | Accepted |
