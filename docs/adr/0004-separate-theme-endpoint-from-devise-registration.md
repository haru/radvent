# 0004. Separate theme endpoint from Devise registration

## Status

Accepted

## Context

The manual theme-switching feature (spec: `specs/007-theme-switch/spec.md`)
adds a Light/Dark/System choice to "マイページ", which is the Devise
`edit_user_registration_path` view (`app/views/devise/registrations/edit.html.haml`).
That view's existing form updates email/name/password through Devise's
`RegistrationsController#update`, which requires `current_password` to be
filled in (`app/views/devise/registrations/edit.html.haml`, the Devise
registration flow).

The theme requirement is different in kind: selecting a theme must apply
immediately and save without any extra confirmation (FR-004, SC-001 in
`specs/007-theme-switch/spec.md`). Routing the theme value through the
Devise registration form would force one of:

- Requiring `current_password` on every theme change, which contradicts
  "即座に反映" (immediate reflection) and would be a poor experience for a
  non-sensitive preference.
- Special-casing the Devise controller to skip `current_password` only for
  the `theme` param, entangling unrelated concerns (credentials vs. display
  preference) in one controller/action.

## Decision

Add a dedicated `PATCH /theme` route backed by a new `ThemesController`
(`app/controllers/themes_controller.rb`), independent of
`Devise::RegistrationsController`. It requires only `authenticate_user!`,
accepts `{ theme: "light" | "dark" | "system" }`, and updates
`current_user.theme` directly. The theme UI lives in the same "マイページ"
view as the Devise form, but posts to this separate endpoint via a Stimulus
controller (`app/javascript/controllers/theme_controller.js`) instead of
the page's main form.

## Consequences

- The existing Devise registration update flow (email/name/password,
  `current_password` requirement) is untouched — no risk of regressing
  account-security behavior while adding an unrelated preference.
- Theme changes get their own lightweight JSON contract
  (`specs/007-theme-switch/contracts/theme-update.md`), independent of
  Devise's redirect/flash-based update flow, which is what allows immediate
  client-side application without a full form submission.
- Future settings that shouldn't require `current_password` (if any) have a
  precedent to follow: a small dedicated controller/endpoint rather than
  extending the Devise registration form.
