---
title: Manual Theme Selection (Light/Dark/System)
type: decision
sources: [S015, S016, S017]
updated: 2026-09-17
---

# Manual Theme Selection (Light/Dark/System)

Feature `007-theme-switch` (branch, 2026-09-16) changes theming from
fully-automatic (OS `prefers-color-scheme` only) to user-selectable: My Page
gains a Light/Dark/System setting, applied immediately and persisted per user
(S015).

## Storage

`users` gains a `theme` string column (`default: 'system'`, `null: false`),
exposed via `enum :theme, %w[system light dark]` (Rails 8.1 string-backed
enum) on `User` — see [Domain Model](./domain-model.md) (S015). Rejected: an
integer-backed enum (unreadable values in migrations/debugging) and a generic
JSON `settings` column (YAGNI — theme is the only setting today) (S015).

## My Page and the save endpoint

"My Page" is Devise's `edit_user_registration_path`
(`devise/registrations/edit`), not a dedicated controller; the theme UI is
added there. Saving goes through a **new, separate** lightweight endpoint
(`PATCH /theme` → `ThemesController#update`) rather than Devise's own
registration-update form — see
[Controllers and Routing](./controllers-and-routing.md) (S015). Devise's form
requires `current_password` for any update, which is incompatible with
selecting a theme and having it reflected immediately; theme changes aren't
sensitive enough to justify that friction (S015). Rejected: overriding
Devise's `RegistrationsController` to accept theme changes on the same form
(would bypass or complicate the `current_password` requirement) (S015).

## CSS: `data-theme` attribute over pure media query

`application.scss`'s plain `@media (prefers-color-scheme: dark)` block is
reorganized into `data-theme`-based selectors — see
[Views and Frontend](./views-and-frontend.md#styling) (S015):
- `:root[data-theme="dark"] { ... }` — applies unconditionally when Dark is
  selected.
- `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }`
  — applies only when `data-theme` is `system` or unset, preserving today's
  OS-driven behavior exactly for that case.

`<html>` renders `data-theme` server-side
(`current_user&.theme || 'system'`) to avoid a flash of the wrong theme on
load. Existing CSS variable *values* are unchanged — only the switching
mechanism changes (S015). Rejected: adopting MDB/Bootstrap's `data-bs-theme`
(the project already manages colors via its own CSS variables, not
Bootstrap's dark-mode utilities) and rewriting inline styles via JS (breaks
the single-source-of-truth CSS-variable design and complicates SSR/FOUC
avoidance) (S015).

## Immediate reflection

A new Stimulus controller, `theme_controller.js`, handles the `change` event
on the theme picker — see
[JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md) (S015):
1. Writes `document.documentElement.dataset.theme` immediately (UI updates
   with no server round-trip).
2. `fetch`-PATCHes `/theme` with the CSRF token.
3. On failure, reverts `data-theme` to its prior value and shows an error —
   no silent fallback, matching the project's explicit-error-handling
   convention (S015, S016).

Rejected: a Turbo Stream form submission, which would wait for a server
round-trip before updating the UI, missing the "reflected immediately"
requirement (S015).

## ERB → HAML conversion

`app/views/devise/registrations/edit.html.erb` is a pre-existing ERB view —
a holdover that violates the project's HAML-only view rule. Since this
feature must edit that file anyway, it is converted to `edit.html.haml` as
part of the change; the existing email/password/`current_password` fields and
behavior are carried over unchanged, out of scope for this feature (S015).

This conversion was later cited as precedent by `008-fix-dark-theme` to
justify converting the *rest* of Devise's views the same way — see
[Devise Auth Views: ERB → HAML + .panel → .card](./devise-views-format-conversion.md)
for why that follow-up is flagged, not taken at face value (S017).

## Documentation requirement

The plan flags two decisions here — separating My Page's save flow from
Devise's registration form, and moving CSS to a `data-theme`-attribute
scheme — as significant enough to require an ADR under `docs/adr/` (S016).

See [Domain Model](./domain-model.md) for the `User#theme` field and
[Controllers and Routing](./controllers-and-routing.md) for the new route and
controller.
