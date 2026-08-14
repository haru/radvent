---
title: Controllers and Routing
type: component
sources: [S004, S009]
updated: 2026-08-14
---

# Controllers and Routing

## Routing

`config/routes.rb` roots to `welcome#index` and uses standard Rails RESTful
routes with slug-based access for the main entities (S004):

- Events: `get 'events/:name' => 'events#show'` — accessed by `name` slug,
  not numeric ID (S004).
- Boards: slug parameter constrained to alphanumeric characters and hyphens
  (S004).
- Admin routes: `delete 'users/delete/:id'`, `put 'user/:id/update'` (S004).
- Items: both collection and member preview routes, to support live
  Markdown preview before persistence (S004).

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
  `admin` flag set (S004); see [Domain Model](./domain-model.md#authorization).
- `check_visibility` (`BoardsController`) — restricts board access based on
  the `visibility` enum (`public` / `protected` / `private`) (S004).
- `edit_permission?` (Items / AdventCalendarItems controllers) — allows edits
  only for the content's creator or an admin (S004).

The user-boards design spec calls for a more general, object-level
`visible?`/`editable?`/`deletable?` interface on the affected models rather
than one-off controller filters — see
[User Boards & Multi-Event Support](./user-boards-feature.md) (S009). It's
not confirmed whether `check_visibility`/`edit_permission?` are the
controller-side callers of that interface or a separate mechanism.

## Controller groups

| Group | Responsibility |
|-------|-----------------|
| Boards / BoardMemberships | Board lifecycle, visibility-based access, membership management (add/remove users by email or name) (S004) |
| Events / AdventCalendarItems | Advent calendar management, date-slot assignment (`date` is Integer 1–31) (S004) |
| Items | Content creation for a calendar slot, plus the Markdown preview pipeline (S004) |
| Users | Admin-only account/profile management (S004) |
| Comments / Likes | Social interaction on items; `Comment` has no `user_id` — stores `user_name` as a string (S004) |
| Attachments | Image uploads via CarrierWave for the Markdown editor (S004) |

See [Domain Model](./domain-model.md) for the underlying entities and
[Tech Stack](./tech-stack.md) for Devise and the locale-detection stack.
