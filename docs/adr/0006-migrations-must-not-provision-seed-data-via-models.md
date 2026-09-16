# 0006. Migrations must not provision seed data via ActiveRecord models

## Status

Accepted

## Context

`db/migrate/20171030012929_create_default_admin_user.rb` created the default
admin account via `User.create!(...)`, duplicating what `db/seeds.rb` already
does behind a `User.none?` guard.

Adding `theme` as an `enum` on `User`
(`db/migrate/20260916140954_add_theme_to_users.rb`) broke this migration on
any environment that runs the full migration history against an empty
database (CI, a fresh install). `db:migrate` replays migrations in
chronological order, so when `CreateDefaultAdminUser#up` ran, it loaded the
*current* `User` class — including the `theme` enum — while the `users`
table at that point in history still had no `theme` column. Rails 8.1
validates that an `enum` is backed by a real column as soon as the model's
schema is loaded, so `User.create!` raised:

```
Undeclared attribute type for enum 'theme' in User. Enums must be backed by
a database column or declared with an explicit type via `attribute`.
```

Every environment with an already-migrated database was unaffected (this
migration was already recorded as applied, so it never re-ran), which is why
this went unnoticed until CI ran the full history from scratch.

This is a more general hazard than the one in [0002](0002-migration-must-self-provision-backfill-dependencies.md):
0002 is about a migration's *own backfill* depending on data another process
was supposed to have created first. Here, the migration itself does not need
to create this data at all — `db/seeds.rb` already owns it, idempotently —
but routing that creation through the live `User` model still ties an
old migration's success to *all future* schema changes on that model,
forever, for no benefit.

## Decision

Migrations must not create seed/fixture-style records (an initial admin
user, default settings, and similar one-off rows meant for every install)
through an ActiveRecord model class. That responsibility belongs to
`db/seeds.rb` (or an equivalent idempotent, model-based seed script), which
runs after `db:migrate` completes and therefore always sees the finished
schema, not a snapshot from wherever that migration falls in history.

Concretely, `CreateDefaultAdminUser#up`/`#down` are now empty. The file is
kept, unmodified in intent, only so its already-applied version is not
replayed on existing databases; `db/seeds.rb`'s `User.none?` guard is now
the sole place the default admin account is created.

This does not change guidance from 0002: a migration that backfills a
column it just added (a NOT NULL constraint, a foreign key) must still
self-provision that data itself, in the same migration, via raw SQL. That
data is structurally required for the migration's own DDL to succeed. A
seed-style convenience record like the default admin user is not; it can
and should wait for `db:seed`.

## Consequences

- Migrations that need a default/seed record must add it to `db/seeds.rb`
  (or extend an existing idempotent seed step there) instead of writing to
  the model directly.
- `db/seeds.rb` remains the only place that must run after `db:migrate` for
  a fresh install to have a working default admin login
  (`bundle exec rake db:create db:migrate db:seed`, per `README.md`).
  `build-scripts/install.sh` (used by CI) intentionally calls `db:seed`
  after `db:migrate` too, to verify seeding itself does not raise; the test
  database it seeds is restored to a clean, empty schema before the test
  suite runs, so no test depends on the seeded admin/board rows existing.
- Reviewers should flag any new migration that calls `.create!`/`.save!`
  (or similar) on an application model purely to provision default/seed
  data, rather than to backfill that migration's own schema change.
