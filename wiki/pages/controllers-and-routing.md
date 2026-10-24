---
title: Controllers and Routing
type: component
sources: [S004, S009, S013, S015, S019, S024, S028]
updated: 2026-10-24
---

# Controllers and Routing

## Routing

`config/routes.rb` roots to `welcome#index` and uses standard Rails RESTful
routes with slug-based access for the main entities (S004):

- Events: `get 'events/:name' => 'events#show'` — accessed by `name` slug,
  not numeric ID (S004). TOP board events keep this name-only URL; user board
  events are addressed as `/boards/:board_board_id/events/:name`, and a
  name-only URL that matches no TOP board event redirects to the board-scoped
  URL only when exactly one visible user board event has that name
  (see ADR 0009).
- Boards: slug parameter constrained to alphanumeric characters and hyphens
  (S004).
- Admin routes: `delete 'users/delete/:id'`, `put 'user/:id/update'` (S004).
- Items: both collection and member preview routes, to support live
  Markdown preview before persistence (S004). The collection `POST
  /items/preview` routes to `items#preview_new` (path helper
  `preview_items_path` unchanged); see
  [Article Preview Authorization](./article-preview-authorization.md) (S028).
- Theme: `patch 'theme' => 'themes#update'` (feature `007-theme-switch`) — a
  lightweight, `current_user`-only endpoint deliberately kept separate from
  Devise's registration-update route so a theme change doesn't require
  `current_password`; see
  [Manual Theme Selection](./theme-switch.md) (S015).
- Other-boards listing: `get 'boards/:board_ref_id/other_boards' =>
  'board_other_boards#index'` (feature `009-board-list`) — uses `Board`'s
  numeric `id` rather than the `board_id` slug, because TOP boards have no
  slug; see [Other Boards Listing](./other-boards-listing.md) (S019).

Slug-based routes for events/boards require careful route ordering to avoid
conflicts with other resource routes (S004).

## Layouts

Two layouts (S004):
1. **Application layout** (default) — welcome pages, calendar views, item
   displays; standard navbar and flash messages.
2. **Admin layout** — management screens; controllers must explicitly switch
   to it (e.g. `UsersController`).

A controller that forgets to declare the admin layout silently falls back to
the application layout, which risks exposing admin views to public users
(S004). See [Views and Frontend](./views-and-frontend.md) for the HAML
templating and `content_for` conventions inside those layouts.

## ApplicationController

All controllers inherit from `ApplicationController`, which provides (S004):
- CSRF protection via `protect_from_forgery`
- Locale detection via `HttpAcceptLanguage` (see [Tech Stack](./tech-stack.md))
- Helpers for rendering 404 and 403 responses

## Authorization filters

- `admin_user!` — renders 403 Forbidden unless the signed-in user has the
  `admin` flag set (S004); see [Authorization](./authorization.md).
- `check_visibility` (`BoardsController`; also the Events / Items /
  AdventCalendarItems `show` actions) — 404 unless the board's `visible?`
  rule holds (`public` / `protected` / `private`) (S004); see
  [Board Visibility on Show Pages](./show-page-visibility.md) (S024).
- `edit_permission?` (Items / AdventCalendarItems controllers) — allows edits
  only for the content's creator or an admin (S004).
- `check_deletability` (`BoardsController`) — gates `destroy` via
  `Board#deletable?`. The action further requires the submitted
  `confirm_board_id` param to match the board's actual ID
  (`Board#board_id_match?`) before it will delete, independent of and after
  this authorization check — see
  [Board Deletion — ID Confirmation & Dialog](./board-delete-id-confirmation.md)
  (S013).

The user-boards design spec calls for a more general, object-level
`visible?`/`editable?`/`deletable?` interface on the affected models rather
than one-off controller filters — see
[User Boards & Multi-Event Support](./user-boards-feature.md) (S009).
`check_visibility` is the controller-side caller of `visible?` (S024); it's
not confirmed whether `edit_permission?` calls that interface or a separate
mechanism.

The per-controller responsibility table lives in
[Controller Groups](./controller-groups.md) (split out at the 600-word
threshold).
