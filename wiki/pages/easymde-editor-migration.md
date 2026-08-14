---
title: EasyMDE Editor Migration
type: decision
sources: [S011]
updated: 2026-08-14
---

# EasyMDE Editor Migration

Feature `002-easymde-editor` (spec, drafted 2026-02-28) plans to complete the
migration of the item authoring editor to EasyMDE's built-in feature set,
retiring the custom split-pane preview and legacy upload UI that
[Views and Frontend](./views-and-frontend.md) currently documents (S011).

## What changes

- The custom right-side preview pane (`#item-preview-content`) and its
  layout are removed; EasyMDE's own preview and side-by-side modes replace
  it (S011).
- The Markdown help modal and its `?` trigger button are removed — EasyMDE's
  built-in guide button takes over that role (S011).
- The existing file-select attachment UI is removed; image upload happens
  only through EasyMDE's toolbar upload button, still hitting the existing
  `AttachmentsController` endpoint unchanged (S011). See
  [JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md) for how
  `editor_controller`'s `_uploadImage` currently performs that upload, and
  [Toolbar Image Upload — UX and Access Control](./image-upload-toolbar-button.md)
  for that button's detailed UX and permission behavior (S012).
- Fullscreen mode is added as a toolbar option.

## Decisions from the clarification session (2026-02-28)

- **Preview/help retirement**: both the custom preview pane and the Markdown
  help modal are dropped in favor of EasyMDE's built-ins — no dual
  maintenance of two preview paths (S011).
- **XSS sanitization scope**: only the editor's own preview/side-by-side
  rendering is sanitized as part of this feature; the article *display*
  page's Markdown rendering is explicitly out of scope and keeps its current
  behavior (S011). See `markdown_controller`'s `marked` + `DOMPurify` pipeline
  in [JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md),
  which already sanitizes the display page — the editor preview needs its
  own equivalent.
- **Image upload UI**: EasyMDE's built-in toolbar button was chosen over
  keeping the legacy file-select UI, which is deleted entirely (FR-009,
  FR-013) (S011).
- **Upload failure handling**: on upload failure, an error message is shown
  at the top of the editor (using EasyMDE's standard mechanism) and the
  editor's existing content is left untouched (FR-016) (S011).
- **Mobile scope**: only basic text input and form submission are guaranteed
  on mobile; side-by-side and fullscreen modes are explicitly not
  mobile-supported (FR-017) (S011).

## Success criteria worth remembering

- Editor and toolbar must be usable within 5s of opening the item form;
  preview/side-by-side switches must complete within 1s (S011).
- Zero regression bar: the full existing test suite must keep passing after
  the migration (S011).

## Out of scope

Article display-page rendering, the comment editor, and offline/autosave
support are explicitly excluded from this feature (S011).
