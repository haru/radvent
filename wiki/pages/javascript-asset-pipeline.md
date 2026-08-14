---
title: JavaScript and CSS Asset Pipeline
type: component
sources: [S010, S011, S012]
updated: 2026-08-14
---

# JavaScript and CSS Asset Pipeline

Detail layer under [Views and Frontend](./views-and-frontend.md)'s dual
Sprockets/esbuild summary — see that page for the general templating and
styling picture.

## JS entry point

`app/javascript/application.js` wires up: MDB UI Kit (ES module import with
custom re-init, see below), Turbo + ActiveStorage, FontAwesome, the Stimulus
controller manifest, and a listener on `[data-dismiss="alert"]` clicks for
Devise alert dismissal (S010).

## MDB / Turbo lifecycle gotcha

MDB components need manual re-initialization after Turbo swaps in new
content, or dynamically-loaded forms (item editor, comment forms) render
unstyled. A `mdbInputUpdate` helper finds all `.form-outline` elements and
calls `new mdb.Input(el).init()` / `.update()`, bound to `turbo:load` and
`turbo:render` (S010).

## Stimulus controllers

| Controller | Purpose |
|-----------|---------|
| `markdown_controller` | Renders Markdown via `marked` + `DOMPurify`; triggers `hljs.highlightBlock` for code blocks (S010) |
| `comment_controller` | Renders comments; uses a `rendered` data-attribute flag so Markdown is converted exactly once, preventing double-render (S010) |
| `editor_controller` | Manages the EasyMDE instance; its `_uploadImage` function handles image uploads (below) (S010) |
| `datatable_controller` | Initializes `simple-datatables` for admin list views (search/sort) (S010) |
| `popover_controller` | MDB Popover lifecycle — init on `connect`, dispose on `disconnect` (S010) |
| `navbar_dropdown_controller` | Mobile/desktop dropdown state; closes on outside click (S010) |

Controllers are auto-registered via a manifest rather than explicit imports —
this cuts boilerplate but means a controller's filename/naming must follow
Stimulus's convention or it silently won't register (S010).

## CSS pipeline

`postcss-cli` processes `app/javascript/stylesheets/application.css` with
`postcss-import`, `postcss-flexbugs-fixes`, and `postcss-preset-env` (stage 3
+ Autoprefixer) (S010). That manifest imports MDB UI Kit, EasyMDE styles, and
Simple-DataTables styles (S010). SCSS partials of note in
`app/assets/stylesheets/partials/`: `users.scss` (fixes a Bootstrap 4 → 5
close-button regression in Devise alerts), `comments.scss` / `likes.scss`
(interaction layout), `advent_calendar_items.scss` (calendar grid) (S010).

## Image upload flow

`editor_controller`'s `_uploadImage`: client-side checks a 10MB size limit
and a JPEG/PNG/GIF/WebP whitelist before sending; reads the CSRF token from
the document's meta tags; `fetch`-POSTs to `AttachmentsController#create`,
which stores the file via CarrierWave's `ImageUploader` and returns JSON with
`image_url`; the client inserts that as Markdown image syntax at the cursor
(S010). See [Domain Model](./domain-model.md) for the `Attachment` model.

**Planned**: feature `002-easymde-editor` moves the upload entry point to
EasyMDE's own toolbar image button, deleting the legacy file-select UI
entirely; the endpoint and response handling stay the same, and on upload
failure the editor must show an error at the top of the editor and leave
existing content untouched. See
[EasyMDE Editor Migration](./easymde-editor-migration.md) (S011).

Feature `003-image-file-upload` specifies that button's behavior in detail:
a spinner shown and the button disabled for the duration of the upload;
upload gated by the same `edit_permission?` check used elsewhere (see
[Domain Model](./domain-model.md#authorization)), while viewing an uploaded
image's URL remains unrestricted. Full decision record in
[Toolbar Image Upload — UX and Access Control](./image-upload-toolbar-button.md)
(S012).
