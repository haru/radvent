# 0007. Serve new images through an authorized endpoint

## Status

Accepted

## Context

Article images were stored under `public/uploads` and served as static files
(`RAILS_SERVE_STATIC_FILES=true`), so anyone with the URL could fetch an image
from a private board without any authorization check. Images uploaded before
this change must keep working at their existing URLs.

## Decision

- New images are stored outside `public/`, under
  `Rails.application.config.x.protected_upload_root`
  (`storage/protected_uploads`, or `RADVENT_PROTECTED_UPLOAD_DIR`; in Docker
  `/var/radvent_data/protected_uploads`). CarrierWave's `cache_dir` is moved
  there too, so temporary files are never publicly reachable.
- `GET /attachments/:id/:filename` (`AttachmentsController#show`) serves them
  with `send_file` only when `Attachment#visible?(current_user)` is true: the
  article's board must be visible and the article published, unless the
  viewer may edit it (author or admin), who needs the image before release.
  Denied, unknown, mismatched-filename, legacy, unreadable and missing images
  all return the same 404, so existence is not revealed. The file path is
  built by the uploader from the stored identifier, never from
  `params[:filename]`.
- No schema change distinguishes legacy from new images. `ImageUploader#root`
  looks in the protected area first and falls back to `public/` only when the
  saved record's file exists there (`ImageUploader#legacy?`). Legacy files and
  URLs are never touched. `image.url` is therefore only meaningful for legacy
  images; new images are linked through `attachment_image_path`.
- Responses carry `Cache-Control: no-cache, private`, so permission changes
  take effect on the next request and shared caches do not store images.

## Consequences

- Images are served by Rails, which costs more than static serving. Legacy
  images are unaffected. `X-Sendfile` / `X-Accel-Redirect` is a possible future
  optimization when a reverse proxy is in front.
- `protected_uploads` must be persisted alongside `uploads`.
- No ETag or Last-Modified is sent, so browsers download a protected image
  again on every view.
- Legacy images remain publicly readable until they are migrated, which is out
  of scope here.
