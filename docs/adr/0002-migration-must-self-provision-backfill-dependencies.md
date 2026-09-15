# 0002. Migrations must self-provision their backfill dependencies

## Status

Accepted

## Context

`db/migrate/20260304150524_add_board_to_events.rb` adds `events.board_id`
and backfills it by looking up the single `board_type: top` row in `boards`:

```sql
UPDATE events
SET board_id = (SELECT id FROM boards WHERE board_type = 0 LIMIT 1)
WHERE board_id IS NULL
```

The only place that ever created that top board was `db/seeds.rb`
(`Board.find_or_create_by!(board_type: :top) { |b| b.name = 'TOP' }`), which
is not part of `rake db:migrate` and is not guaranteed to have run before it.

On any environment that already had `events` rows and had not yet run
`db:seed`, the subquery returned `NULL`, `events.board_id` stayed `NULL` for
every row, and the following `change_column_null :events, :board_id, false`
failed with a NOT NULL violation.

On transactional adapters (PostgreSQL, SQLite), Rails runs a migration inside
a transaction, so this failure rolled back the whole migration and it was
never recorded as applied. On MySQL, DDL statements (`add_column`,
`add_index`) are not transactional and implicitly commit, so the column and
index from the earlier steps stayed in place even though the migration
failed and never got recorded — leaving the database in a partially-migrated
state that a plain re-run of `db:migrate` could not cleanly recover from.

## Decision

A migration must not assume that some other, independently-scheduled process
(a seed file, a rake task, an operator runbook) has already provisioned the
data it needs to backfill a new NOT NULL column. It must create that data
itself, idempotently, as part of the same migration.

Concretely, `AddBoardToEvents` now inserts the missing `board_type: top` row
itself, immediately before the backfill `UPDATE`, using a cross-database
`INSERT ... SELECT ... WHERE NOT EXISTS` (see
`db/migrate/20260304150524_add_board_to_events.rb`). This runs in plain SQL
rather than through the `Board` model, consistent with AGENTS.md's guidance
for raw SQL in migrations (`CURRENT_TIMESTAMP`, no ActiveRecord model
coupling), and it uses the same `board_type` value and `name` that
`db/seeds.rb` uses, so a later `db:seed` run finds the existing row via
`find_or_create_by!` instead of creating a duplicate.

This applies to future migrations too: if a migration's backfill depends on
a row or table existing, the migration creates that dependency itself rather
than delegating it to seeds, another migration, or documentation telling an
operator to run something first.

## Consequences

- Migrations that backfill data may need a small amount of setup SQL of
  their own; this is preferred over relying on seed data or operational
  convention.
- `db/seeds.rb` keeps working unmodified, since `find_or_create_by!` is
  naturally idempotent against a row a migration already created.
- Reviewers should flag any new migration that backfills a NOT NULL column
  by referencing data it does not also guarantee exists.
