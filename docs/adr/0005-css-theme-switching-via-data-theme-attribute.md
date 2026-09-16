# 0005. CSS theme switching via data-theme attribute

## Status

Accepted

## Context

Before this feature, `app/assets/stylesheets/application.scss` defined the
dark palette entirely inside `@media (prefers-color-scheme: dark) { ... }`,
so Light/Dark followed the OS setting with no way for a user to override it.
The manual theme-switching feature (`specs/007-theme-switch/spec.md`)
requires a user-selectable Light/Dark/System choice (FR-001–FR-005) that
takes effect immediately (SC-001), while leaving the existing color values
themselves unchanged (FR-010) and leaving "System" behaving exactly as
before (FR-005, FR-011, SC-004).

The original dark block contained two kinds of rules that both needed to
become theme-aware, not just the `:root { --var: ... }` custom-property
block: `body#advent_calendar_body { ... }` also carries dark-specific
literal colors (e.g. `color: #ddd`, `border-color: #fff`) for form
controls, cards, and tables that do not go through a CSS variable. Only
converting the `:root` variables would have left those elements
unstyled when a user manually selects Dark while the OS is set to Light
(and vice versa) — a partial, visually broken theme switch.

## Decision

Render `data-theme` on `<html>` server-side from `current_user&.theme ||
'system'` (`app/views/layouts/application.html.haml`), so the correct
theme is present before first paint (avoids FOUC). Extract the entire
former dark rule set (`:root` variables and the `body#advent_calendar_body`
overrides) into a single SCSS mixin, `dark-theme-styles($root-selector)`
(`app/assets/stylesheets/application.scss`), and include it twice:

- `:root[data-theme="dark"]` — applies unconditionally when the user has
  explicitly selected Dark, regardless of the OS setting.
- `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }`
  — applies only when the user has not explicitly selected Light (i.e.
  `system`, or no value set), so it continues to just follow the OS
  setting, unchanged from before this feature.

A Stimulus controller (`app/javascript/controllers/theme_controller.js`)
then flips `document.documentElement.dataset.theme` on the client the
moment the user picks a radio option, before the save request resolves.

## Consequences

- Selecting Dark or Light always produces a fully-themed screen regardless
  of the OS setting, because both the CSS variables and the literal
  dark-mode overrides are scoped by the same `data-theme` condition.
- The dark palette's actual color values are defined in exactly one place
  (the mixin body), so `application.scss` does not duplicate the color
  literals between the "explicit dark" and "OS-driven dark" cases.
- Anyone extending the dark palette in the future must add rules inside
  `dark-theme-styles`, not as a new top-level `@media
  (prefers-color-scheme: dark)` block, or the new rules will not respond to
  a manual theme selection.
