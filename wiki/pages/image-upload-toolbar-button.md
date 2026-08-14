---
title: Toolbar Image Upload — UX and Access Control
type: decision
sources: [S012]
updated: 2026-08-14
---

# Toolbar Image Upload — UX and Access Control

Feature `003-image-file-upload` (spec, drafted 2026-05-30) specifies the
behavior of the Markdown editor's toolbar image-upload button — the same
button [EasyMDE Editor Migration](./easymde-editor-migration.md) (feature
`002-easymde-editor`) introduces to replace the legacy file-select UI. This
spec fills in UX and access-control details that feature didn't cover (S012).

## Upload flow

Click toolbar button → native file dialog (filtered to JPEG/PNG/GIF/WebP) →
upload → Markdown image tag (`![image](URL)`) auto-inserted at the cursor →
visible in the Markdown preview (S012). Matches the existing 10MB size limit
and format whitelist already enforced by `editor_controller`'s
`_uploadImage` — see
[JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md) (S010,
S012). Only one file per operation; multi-file selection is out of scope
(S012).

## Decisions from the clarification session (2026-05-30)

- **In-progress feedback**: the toolbar button shows a spinner during
  upload and is disabled (not re-clickable) until the upload completes
  (FR-009) (S012).
- **Upload authorization**: uploading is gated on the user having edit
  permission on the target item — the existing `edit_permission?` guard (see
  [Domain Model](./domain-model.md#authorization)) — but **viewing** an
  uploaded image's URL gets no new access control: anyone who knows the URL
  can view it, regardless of the item's public/protected/private state, same
  as existing clipboard-paste-uploaded images. View-time authorization is
  explicitly out of scope for this feature (FR-008, FR-010) (S012).
- **Unsaved-item images**: images uploaded before the item is saved follow
  the same existing behavior as clipboard paste — no new handling was added
  (S012).

> Note: [User Boards & Multi-Event Support](./user-boards-feature.md)'s
> design spec (S009) calls for `Attachment` to eventually implement a
> `visible?(user)` interface alongside `Board`/`Event`/`Item`. This feature
> explicitly keeps Attachment viewing unrestricted for now — not a
> contradiction (S009 is a forward-looking design target, S012 is this
> feature's current scope), but the two should be reconciled if/when
> per-object Attachment visibility is implemented.

## Edge cases worth remembering

- Uploading the same file twice produces two independent URLs (S012).
- Canceling the file dialog leaves the editor content unchanged (S012).
- Navigating away from the edit screen mid-upload aborts that upload
  (S012).

## Out of scope

Mobile camera capture, image resize/crop, embedding by external URL, and
batch/multi-file upload are explicitly excluded (S012).
