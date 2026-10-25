---
title: Event Addressing by Board (Name Collision Fix)
type: decision
sources: [S029, S030]
updated: 2026-10-25
---

# Event Addressing by Board (Name Collision Fix)

Feature `015-env-log-event-collision` (V-14) fixed a defect: event `name` is
unique only within a board, yet every event page was looked up with
`Event.find_by(name:)` across all boards, so which of two same-named events
opened depended on database order (S029, S030). The decision is recorded in ADR 0009
(S029). Companion fix in the same feature:
[Startup Log Secret Hygiene](./startup-log-secret-hygiene.md).

## Decisions

- **Nested route for user boards.** `resources :events, param: :name, only:
  %i[show edit update destroy]` is nested inside `resources :boards`, giving
  `/boards/:board_board_id/events/:name` (the `board_board_id` name matches the
  existing `board_memberships` nesting). Name-only routes are unchanged so
  externally shared TOP board URLs keep working; `new`/`create` are not nested
  (S029).
- **Lookup depends on URL shape.** Board-scoped URL: search only that
  `board_type_user` board (404 if none, so a TOP event cannot be opened this
  way). Name-only URL: search only TOP board events, regardless of DB order
  (S029).
- **Model scopes.** `Event.on_top_board`, `Event.on_user_boards`, and
  `Event.sole_visible_on_user_boards(name, user)`, which returns the event only
  when exactly one user-board event of that name is visible to the user, else
  `nil`. Reuses `Board#visible?` instead of a second SQL rule (S029).
- **Legacy URL redirect.** For a name-only URL with no TOP match, `show` and
  `edit` answer **302** to the board-scoped URL when exactly one visible
  candidate exists, otherwise 404; `update` and `destroy` always 404. 302 (not
  301) lets later same-name events change the outcome. Only visibility is
  counted, so hidden events leak neither through the redirect nor through
  response differences (S029).
- **Visibility before permission.** `check_visibility` now covers `show edit
  update destroy`; order is find (404) → visible (404) → edit permission (403).
  Behaviour change: the creator of a private-board event who was removed from
  the board now gets 404 instead of being able to edit (S029).
- **One link rule.** `ApplicationController#event_page_path(event)` and
  `edit_event_page_path(event)` (both `helper_method`s) pick the TOP or board
  URL; five link/redirect sites use them (S029).
- **Rejected:** a globally unique event name (reverses the intentional
  per-board calendars and could fail on existing duplicates), moving TOP
  events under `/boards/top/...` (breaks shared links), a `Board.visible_to`
  scope (duplicates `visible?`), a candidate-list page (YAGNI) (S029).
- No schema or data change (S029).

Related: [Controllers and Routing](./controllers-and-routing.md),
[Authorization](./authorization.md),
[Board Visibility on Show Pages](./show-page-visibility.md).
