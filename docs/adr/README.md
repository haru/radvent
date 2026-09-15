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
