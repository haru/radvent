---
title: Dark Theme — Full-App Color Coverage
type: decision
sources: [S017, S018]
updated: 2026-09-17
---

# Dark Theme — Full-App Color Coverage

Feature `008-fix-dark-theme` (branch, 2026-09-16/17) closes gaps left after
`007-theme-switch` introduced the `data-theme` switching mechanism (S018) —
see [Manual Theme Selection](./theme-switch.md). Several screens still had
white-background/black-text values hardcoded outright, so switching to Dark
didn't change them. No new theming mechanism, data model, or JS logic is
added; every fix routes through the existing CSS custom properties and the
`dark-theme-styles` mixin in `application.scss` (S017, S018).

## Tables (calendar and list views)

`application.scss`'s existing `.table thead th` rule only overrides text
color; Bootstrap's default white table background survives into Dark mode.
Fix: add `background-color: var(--main-bg-color)` to the shared
`table.table` rule (rather than per-view classes) so the calendar table,
user list, board list, and board-member list — which each write their own
`%table.table.table-striped` markup with no shared partial — are all covered
by one change. The calendar's hardcoded `border-color: #ddd` also moves to a
`--main-txt-color`-based variable (S017).
Rejected: adding per-view background classes — duplicates the same fix
across every current and future table (S017).

## Comments and footer

`--comment-color` / `--comment-bg-color` are defined only in `:root`, with no
Dark override in the `dark-theme-styles` mixin — the direct cause of
comment bubbles staying light in Dark mode. Fix: add both to the mixin, and
replace `comments.scss`'s hardcoded border (`#d9d9d9`), bubble-arrow colors
(`#d9d9d9`/`#fff`), and author-name color (`#5D310C`) with variable
references. The footer's hardcoded `color: #777` / `border-top: #e5e5e5`
(`welcome.scss`) gets the same treatment (S017).

## Navigation dropdown

`#top-menu .dropdown-item` hardcodes `color: #212529 !important`, and the
dropdown menu background has no Dark override at all — so the user menu
stays white-background/black-text regardless of theme. Fix: replace the
hardcoded text color with a theme variable and add a `.dropdown-menu`
background rule to the Dark mixin, reusing an existing "elevated surface"
token rather than inventing a new one (S017).

## Devise auth views: ERB → HAML + `.panel` → `.card`

Also part of this feature's plan, but split onto its own page because it
carries an implementation flag — see
[Devise Auth Views: ERB → HAML + .panel → .card](./devise-views-format-conversion.md)
(S017).

## Markdown rendering (`.markdown` block)

`items.scss`'s `.markdown` block — fully first-party CSS — hardcodes heading
color (`#777`), blockquote color/border (`#555`/`#ddd`), `<hr>` color
(`#ccc`), and table border/`thead` background (`#ccc`/`#fff`). Same fix
pattern as tables above: replace with existing variables, override via the
Dark mixin (S017).

## EasyMDE editor

EasyMDE's CSS is vendored (`easymde.min.css`, not directly editable). Fix:
add Dark-mode overrides for its output classes (`.CodeMirror`,
`.editor-toolbar`, `.editor-preview`) to the `dark-theme-styles` mixin, so
the app's CSS wins by cascade order over the vendor CSS — the same
after-the-fact override pattern already used for third-party UI, rather than
patching vendor source (which would be lost on upgrade) or swapping editors
(disproportionate to the goal). Scope is limited to background/text contrast
meeting WCAG AA (4.5:1); toolbar icon color and syntax-highlight detail are
out of scope (S017). See
[EasyMDE Editor Migration](./easymde-editor-migration.md) for the unrelated
split-pane-removal decision, and
[JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md#css-pipeline)
for where EasyMDE's CSS is imported.

## Verification method

No new automated tests: the project's test policy scopes RSpec to
controller/model behavior, and this feature changes CSS values and view file
format, not behavior. Contrast (WCAG AA, 4.5:1+) is checked manually via
browser DevTools' contrast checker, documented as a `quickstart.md`
procedure — the same approach `007-theme-switch` used for its
immediate-reflection JS (S017).

See [Views and Frontend](./views-and-frontend.md#styling) for the CSS
variable/mixin system this extends, and
[Manual Theme Selection](./theme-switch.md) for the `data-theme` switching
mechanism these fixes plug into.
