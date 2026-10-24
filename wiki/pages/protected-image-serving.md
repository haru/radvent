---
title: Protected Image Serving (Board Image Access Control)
type: decision
sources: [S021, S022, S023]
updated: 2026-10-24
---

# Protected Image Serving (Board Image Access Control)

Feature `010-board-image-access-control` closes the gap where article images
were publicly fetchable by URL: they sat under `public/uploads`, and in
production `RAILS_SERVE_STATIC_FILES=true` made Puma/Rack serve them with no
authorization (S021). Images now follow the visibility of the article they
belong to. This supersedes the "no view-time access control" decision in
[Toolbar Image Upload — UX and Access Control](./image-upload-toolbar-button.md).

## Decisions

- **Storage**: new images (and CarrierWave's `cache_dir`, so in-flight temp
  files are not public either) live outside `public/`, under
  `config.x.protected_upload_root` — `storage/protected_uploads` by default,
  `RADVENT_PROTECTED_UPLOAD_DIR` to override, `/var/radvent_data/protected_uploads`
  in Docker. `store_dir` (`uploads/attachment/image/<id>`) is unchanged
  (S021, S023). Config details: [Configuration](./configuration.md).
- **Endpoint**: `GET /attachments/:id/:filename` → `AttachmentsController#show`
  → `send_file` (inline), only when `Attachment#visible?(current_user)` holds.
  `:filename` is compared to the stored identifier and never used to build a
  path, so there is no path traversal (S021, S023).
- **One 404 for everything**: denied, unknown id, mismatched filename, orphaned
  attachment, legacy image, and missing or unreadable file all return the same
  404 (no login redirect), so a response never reveals an image exists. A
  missing/unreadable protected file is additionally logged at error level
  (S021, S023).
- **Visibility rule**: `Attachment#visible?` reuses the article's existing
  rule (`AdventCalendarItem` → `Event` → `Board#visible?`; see
  [Authorization](./authorization.md)) and additionally requires the article to
  be *published*, unless the viewer may edit it (author or admin) — otherwise
  future-dated articles' images would leak before release. An orphaned
  attachment is never visible, editable or deletable (S023).
- **Caching**: `Cache-Control: no-cache, private`, so permission changes apply
  on the next request and shared caches never store images. No ETag is sent, so
  images are re-downloaded on every view (S021, S023).
- **Upload API**: `POST /attachments` returns the route-helper path
  (`attachment_image_path`), which also works under a sub-path deployment
  (S021).

## Legacy images

No DB column distinguishes legacy from new images. `ImageUploader#legacy?` is
true only for a saved record whose file is *not* in the protected area but *is*
under `public/`; cached (in-flight) files are never legacy. Legacy files and
their `/uploads/...` URLs are never moved or changed, and stay publicly
readable until migrated (out of scope). Rejected alternatives: an
`access_controlled` column (redundant — always true for new rows), searching
`public/` first (extra failing check for every new image), and `created_at` or
id thresholds (environment-specific) (S021).
`image.url` is therefore only meaningful for legacy images (S023).

## Rejected alternatives

Signed unguessable URLs (leaked links stay valid; revocation not honored),
requiring login for every image (breaks public boards), Active Storage or S3
migration (disproportionate), and `X-Sendfile`/`X-Accel-Redirect` (no reverse
proxy today; a possible future optimization) (S021, S023).

## Operations

`protected_uploads` must be persisted alongside `uploads` — see
[Docker Deployment](./docker-deployment.md). Rails now serves protected
images, which costs more than static serving; legacy images are unaffected
(S023).
