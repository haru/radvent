---
title: Controller Groups
type: component
sources: [S004, S015, S019, S023, S026, S028, S033]
updated: 2026-10-25
---

# Controller Groups

| Group | Responsibility |
|-------|-----------------|
| Boards / BoardMemberships | Board lifecycle, visibility-based access, membership management (add/remove users by email or name) (S004) |
| Events / AdventCalendarItems | Advent calendar management, date-slot assignment (`date` is Integer 1–31) (S004); the slot info page is author/admin only since feature `018` — see [Slot Info Page — Author and Admin Only](./slot-info-page-access.md) (S033) |
| Items | Content creation for a calendar slot, plus the Markdown preview pipeline (S004); previews are authorized — see [Article Preview Authorization](./article-preview-authorization.md) (S028) |
| Users | Admin-only account/profile management (S004) |
| Comments / Likes | Social interaction on items; `Comment` has no `user_id` — stores `user_name` as a string (S004); create/destroy are authorized — see [Comment Authorization](./comment-authorization.md) (S026); likes require sign-in and a readable article — see [Likes Hardening](./likes-hardening.md) (S028) |
| Attachments | Image uploads via CarrierWave for the Markdown editor (S004); `show` (`GET /attachments/:id/:filename`) serves images with access control — see [Protected Image Serving](./protected-image-serving.md) (S023) |
| Themes | Single `update` action persisting `current_user.theme`; added by feature `007-theme-switch` (S015) |
| BoardOtherBoards | Single `index` action returning a page of the viewer's visible boards, newest-activity-first, for the load-more listing; added by feature `009-board-list` (S019) |

See [Controllers and Routing](./controllers-and-routing.md) for routes, layouts and filters,
[Domain Model](./domain-model.md) for the underlying entities and
[Tech Stack](./tech-stack.md) for Devise and the locale-detection stack.
