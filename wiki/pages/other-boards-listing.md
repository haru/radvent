---
title: Other Boards Listing (Load-More Pagination)
type: decision
sources: [S019, S020]
updated: 2026-09-18
---

# Other Boards Listing (Load-More Pagination)

Adds an "other boards" area at the bottom of the board show view — shared by
both TOP and user boards — listing the boards the viewer has permission to
see, newest activity first. Initial render shows up to 10 boards; a "load
more" control fetches 10 more at a time without a full-page reload (S020).

## Sort key: Ruby-side, not SQL

`Board` gets an instance method (`#list_sort_key`) that returns the newest of
three datetimes: the most recent `updated_at` among the board's items whose
`AdventCalendarItem#published?` is true, the most recent `created_at` among
the board's events, and the board's own `created_at`. The listing controller
preloads boards with
`includes(events: { advent_calendar_items: :item })`, filters with the
existing [`Permissionable#visible?`](./authorization.md), then sorts in Ruby
(descending by `list_sort_key`, ties broken by ascending `id`) (S019).

**Rationale**: `Board` has no DB-level visibility scope — `visible?` is only
an instance method, and `BoardsController#index` already loads boards
naively — so a SQL-side sort would still need a Ruby-side `visible?` pass
afterward, weakening the case for a DB aggregation query. Board counts are
assumed small-to-medium (S019), consistent with the app's general
memory-load-and-filter pattern noted in
[Domain Model](./domain-model.md).

**Rejected**: a DB-side `MAX`/`GREATEST` subquery — still needs the Ruby
`visible?` filter afterward, and `GREATEST` behaves differently across
SQLite/MySQL/Postgres; reimplementing `AdventCalendarItem#published?` in SQL
— would duplicate existing logic (S019).

### "Post datetime" definition

Defined as the newest `updated_at` among `Item`s whose `AdventCalendarItem`
is `published?` — not the calendar slot's unlock date itself. `published?`
already matches the spec's "unlocked" concept; `updated_at` gives
finer-grained, unambiguous ordering when multiple items unlock on the same
calendar day, and reorders a board when a published item is later edited
(S019).

## Routing: numeric board ID, not the `board_id` slug

A new route, `GET /boards/:board_ref_id/other_boards`, resolves `board_ref_id`
via `Board.find` (numeric primary key) and is served by a new
`BoardOtherBoardsController#index` — see
[Controllers and Routing](./controllers-and-routing.md) (S019).

**Rationale**: the existing `resources :boards, param: :board_id` routes use
the `board_id` slug, but TOP boards have no `board_id` (the format
validation on that field only applies when `board_type_user?`). A
slug-based endpoint couldn't be called from a TOP board's view, so the
listing and its load-more endpoint use the numeric `id` instead, letting
both TOP and user boards share one mechanism (S019).

**Rejected**: re-rendering all of `boards#show` with a page param (forces a
full-page reload, violating the "no full reload" requirement); a
TOP-board-specific parallel route (duplicates listing logic and view)
(S019).

## Load-more mechanism: Turbo Frame only

The listing area is wrapped in a Turbo Frame; "load more" is a plain link
that Turbo navigates within that frame. No dedicated Stimulus controller or
custom `fetch`/DOM code is written (S019). The `boards/show.html.haml` view
and a shared `_other_boards.html.haml` partial serve both TOP and user
boards, avoiding a duplicated listing implementation per board type (S020).

**Rationale**: `turbo-rails` is already used elsewhere in the app (e.g.
Likes' `turbo_stream` views — see
[JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md)), and a
Turbo Frame satisfies the no-full-reload requirement using only standard
framework behavior (S019).

**Rejected**: a Stimulus controller that fetches JSON and assembles DOM
(duplicate rendering logic between server and client); a `turbo_stream`
append pattern like Likes (this is a plain pagination link, not a form
submission) (S019).

See [Domain Model](./domain-model.md) for `Board`/`Event`/`Item` and
[Controllers and Routing](./controllers-and-routing.md) for the route table.
