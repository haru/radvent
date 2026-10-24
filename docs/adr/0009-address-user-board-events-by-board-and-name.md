# 0009. Address user board events by board id and name

## Status

Accepted

## Context

Event names are unique only within a board (`uniqueness: { scope: :board_id }`),
but every event URL was name-only (`/events/:name`) and resolved with
`Event.find_by(name:)`. When two boards had an event with the same name, the
database picked one arbitrarily: the other board's event could not be opened,
edited or deleted, and a user board event could take over the page of a TOP
board event with the same name.

## Decision

- User board events are addressed by board and name:
  `/boards/:board_board_id/events/:name` (show, edit, update, destroy). `new` and
  `create` are not nested; they keep taking the board as a parameter.
- TOP board events keep the name-only URL. A name-only URL now always means the
  TOP board (`Event.on_top_board`), regardless of creation order.
- A name-only URL that matches no TOP board event is a legacy link. For `show`
  and `edit`, if exactly one user board event with that name is visible to the
  viewer (`Event.sole_visible_on_user_boards`), the response is a `302` to the
  board-scoped URL. Zero or several visible matches, and any `update` or
  `destroy`, answer `404`; the app never guesses between boards. The redirect
  is temporary (not `301`) because the answer depends on which boards exist and
  who is looking.
- `check_visibility` now guards `edit`, `update` and `destroy` as well as
  `show`, ahead of the permission check, so a creator who has lost access to a
  private board gets `404` rather than being able to edit.
- Links and redirects are built by `event_page_path` and `edit_event_page_path`
  (`ApplicationHelper`), which pick the URL form from the board type.
- The uniqueness scope of `name` and its format are unchanged.

## Consequences

- Links generated before this change for user board events keep working while
  the name is unique among visible user boards, and stop working (404) once a
  second visible board uses the same name.
- A legacy name-only link to a user board event shows a different event if an
  event with the same name is later created on the TOP board, because the TOP
  board is always resolved first. The outcome can also differ per viewer, since
  only events visible to that viewer are counted.
- A creator removed from a private board can no longer edit or delete the
  event until re-added; admins still can.
