---
title: "Devise Auth Views: ERB → HAML + .panel → .card (flagged)"
type: decision
sources: [S017]
updated: 2026-09-17
---

# Devise Auth Views: ERB → HAML + `.panel` → `.card`

Split from [Dark Theme — Full-App Color Coverage](./dark-theme-full-coverage.md)
(page exceeded the word cap).

Sign-in, registration, password reset/edit, unlock, and confirmation views
(plus the shared `_error_messages`/`_links` partials) are still `.erb` and
use Bootstrap-3-era `.panel`/`.panel-heading`/`.panel-body` classes that have
no CSS definition in this Bootstrap 5 app, so they render unstyled and don't
track the theme. Feature `008-fix-dark-theme`'s plan converts these to
`.html.haml` and swaps `.panel` for the already-Dark-aware `.card` pattern,
citing the `edit.html.haml` conversion done for `registrations/edit` in
`007-theme-switch` as precedent (S017) — see
[ERB → HAML conversion](./theme-switch.md#erb--haml-conversion).

> ⚠ **Flag for implementation**: this repeats a conversion the user has
> since told a prior session **not** to do to Devise's auto-generated views
> — hand-converted structure is silently lost if `rails g devise:views` is
> re-run after a Devise upgrade. Confirm with the user before carrying out
> this part of the plan; it is not covered by the `registrations/edit`
> precedent, which predates that constraint (no source ID — recorded as
> project feedback, not from an ingested source, so it can't be cited here).

See [Dark Theme — Full-App Color Coverage](./dark-theme-full-coverage.md) for
the rest of this feature's (unflagged) CSS-only fixes, and
[Manual Theme Selection](./theme-switch.md) for the `007-theme-switch`
precedent this cites.
