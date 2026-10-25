---
title: Board Visibility on Show Pages
type: decision
sources: [S009, S024, S025, S031]
updated: 2026-10-25
---

# Board Visibility on Show Pages

Feature `011-private-board-content-visibility` applies the existing
`visible?(current_user)` rule to the three read-only show pages: the calendar
(`EventsController#show`), the article (`ItemsController#show`) and the slot
(`AdventCalendarItemsController#show`). Before it, the rule was enforced only
by the board page and by protected images — see
[Protected Image Serving](./protected-image-serving.md) (S024, S025).

## Decisions

- **Where**: a per-controller `before_action :check_visibility, only: [:show]`
  that calls `visible?` on the loaded record. The rule is not duplicated: it
  resolves through the model delegation `Item` → `AdventCalendarItem` →
  `Event` → `Board#visible?` (admins and the TOP board always pass; private
  boards need owner or membership) (S009, S024). See
  [Authorization](./authorization.md) for the rule itself.
- **Order matters**: the filter is declared *before* `find_board`. The layout
  prints `@board.name` in the navbar for user boards, so halting before
  `@board` is assigned keeps the 404 page from revealing the board (S024).
- **One 404, same as a missing record**: a denied viewer gets the usual
  `render_not_found` page — no login redirect, no distinction between a guest
  and a signed-in non-member, and no hint that the record exists (S024, S025).
- **Visibility before publication**: on the article page the check runs before
  the "not yet published → redirect to root" branch; otherwise that redirect
  would reveal that an unpublished article exists. Viewers who may read the
  board keep the old redirect (S024).
- **No author exception**: only board visibility decides. Having written the
  article or registered the slot does not help once the viewer lost access to
  the board (e.g. was removed as a member). This matches `Attachment#visible?`,
  which also checks board visibility first and only then lets authors see
  unpublished content (S024).
- **No new abstraction**: three one-line private methods, not a shared concern.
  The decision logic already lives once, in the models (S024).
- **No logging of denials**: a denied view is an expected outcome, and the
  existing board page and image 404s are not logged either (S024).

## Scope and testing notes

Only the calendar, article and slot show pages changed: three controllers and
their controller specs, with no model, view, route, schema or i18n change
(S025). Existing specs keep passing because the event factory defaults to the
TOP board, which everyone may see (S024).

When asserting "indistinguishable from a missing record" in a spec, compare
status, rendered template and the absence of the board name — not the whole
HTML, because the CSRF meta token differs on every response (S024).

The entry page's "View" button for published articles relies on this
visibility check having already passed — see
[Entry Page View-Article Button](./entry-page-view-article-button.md) (S031).
