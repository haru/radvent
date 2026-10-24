---
title: Password Reset Hides Account Existence
type: decision
sources: [S028]
updated: 2026-10-24
---

# Password Reset Hides Account Existence

Feature `014-preview-email-exposure` (finding V-10) made the password-reset
request answer identically whether or not an account exists and whether or not
mail delivery works. This is recorded as ADR-0008 in `docs/adr/` (S028). Mail
environment variables: [Configuration](./configuration.md).

## Why Devise's default leaked

`send_reset_password_instructions` adds a `:not_found` error for unknown
addresses, which `create` re-renders as 422; registered addresses got a 303
redirect. A delivery failure (e.g. Missing host, SMTP errors) surfaced only for
registered addresses as a 500. Either difference reveals which addresses are
registered (S028).

## Decisions

- **Subclass and override only `create`.** `Users::PasswordsController <
  Devise::PasswordsController`, routed through `devise_for :users, controllers:
  { passwords: 'users/passwords' }`. `new`, `edit` and `update` (the mailed link
  flow) stay Devise's, and the `devise/passwords` ERB views are untouched (S028).
- **Do not enable `config.paranoid`.** It would still say "sent" for a blank
  address, would not stop delivery exceptions (registered-only 500), and would
  change sign-in behaviour (`fail(:invalid)`, password hashing for unknown
  users) beyond this fix (S028).
- **Flow of `create`.** Normalize the email with Devise's rules (strip,
  downcase); blank → `:blank`, not matching `Devise.email_regexp` → `:invalid`,
  re-render `new` with 422 and send nothing; otherwise call
  `send_reset_password_instructions`, ignore its errors, rescue `StandardError`
  from that call only, log class and message (never the link, token or
  submitted address), do not re-raise, and always flash the existing
  `send_paranoid_instructions` notice and redirect to the sign-in page. The
  format check uses only the submitted string, so it cannot reveal existence
  (S028).
- **Catch `StandardError`, not a list.** Delivery methods raise unrelated
  exception families; a missed one becomes a 500 that itself leaks (S028).
- **No background job, no `Rails.error.report`.** The app has no job backend
  (YAGNI) and no error subscriber; response-time differences are out of scope
  (S028).
- **The ADR exists** because the rescue-and-succeed behaviour is the kind of
  documented fallback the project constitution (IX) allows, and needs its
  reason preserved so it is not "fixed" later (S028).

- **View lookup.** The controller overrides `self.local_prefixes` to `[]`, so
  the shared `devise/passwords` views are always used and a leftover scaffold
  under `app/views/users/passwords` cannot shadow them (S028).
