---
title: Views and Frontend
type: component
sources: [S005, S010, S011]
updated: 2026-08-14
---

# Views and Frontend

Progressive enhancement: server-rendered HAML, Turbo for navigation, Stimulus
for interactivity, SCSS/MDB for styling (S005).

## Templating

All views are HAML (S005). Two layouts (also see
[Controllers and Routing](./controllers-and-routing.md)):
- `application` (`app/views/layouts/application.html.haml`) — head metadata,
  CSRF tags, navbar; child views inject content via `content_for` slots
  (`:jumbotron`, `:content`) rather than full-page rendering (S005).
- `admin` — management screens.

UI strings go through Rails i18n helpers (e.g. `t('menu.sign_in')`)
throughout — hardcoded strings won't localize (S005). See
[Tech Stack](./tech-stack.md) for the locale-detection mechanism.

## JavaScript

Dual asset pipeline: Sprockets handles legacy assets, esbuild
(`node esbuild.config.mjs`) handles modern JS modules — requires care around
asset precedence and bundling order (S005). Build output bundles into
`application_pack.css` and `application.js` (S005).

Libraries: Turbo (fast transitions/partial DOM updates), Stimulus (primary
client-side controller framework, e.g. the `navbar-dropdown` controller for
the user-menu dropdown), MDB (Material Design for Bootstrap components),
EasyMDE (Markdown editor), PostCSS with autoprefixing (S005). Full entry
point, Stimulus controller registry, the MDB/Turbo re-init gotcha, and the
image-upload flow are in
[JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md) (S010).

## Styling

SCSS manifest at `app/assets/stylesheets/application.scss`, with
component partials under `app/assets/stylesheets/partials/` (e.g.
`items.scss`) (S005). Theming uses CSS custom properties (`--main-bg-color`,
`--top-menu-bg-color`, etc.); dark mode switches automatically via a
`prefers-color-scheme` media query — no separate stylesheet or JS toggle
(S005).

## Item authoring UI

Split-pane editor: EasyMDE editor container, a live `#item-preview-content`
pane that renders Markdown client-side as the user types (no server
round-trip), and an `#attachment-image-select` section for image attachment
(S005).

**Planned migration**: feature `002-easymde-editor` retires this split-pane
design — the `#item-preview-content` pane, the Markdown help modal, and the
`#attachment-image-select` file-select UI are all slated for removal in
favor of EasyMDE's built-in preview, side-by-side, fullscreen, and toolbar
image-upload button. See
[EasyMDE Editor Migration](./easymde-editor-migration.md) for the full
decision record (S011).

## Notable UI patterns

- `.event-card` elements show a progress bar for slot-completion status on
  welcome/board views (S005).
- Jumbotron and board-detail content adapt to the board's visibility
  (public/protected/private) (S005).

See [Domain Model](./domain-model.md) for the underlying entities and
[Controllers and Routing](./controllers-and-routing.md) for how layouts are
selected server-side.
