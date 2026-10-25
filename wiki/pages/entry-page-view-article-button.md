---
title: Entry Page — "View Article" Button for Published Articles
type: decision
sources: [S031]
updated: 2026-10-25
---

# Entry Page — "View Article" Button for Published Articles

Feature `017-post-edit-view-link` improves the flow after editing an article:
on the entry information page (`AdventCalendarItemsController#show`,
`advent_calendar_items/show.html.haml`), a published article's author sees a
"View" button instead of "Edit" (S031).

## Behavior

- Inside the existing `editable_by?(current_user)` branch, `published?` picks
  the button: true → `button_show_item` linking to `item_path`; false → the
  unchanged `button_edit_item` linking to `edit_item_path`. Only one of the two
  is ever shown (S031).
- Labels live under `views.advent_calendar_items.show` (ja: 投稿記事を表示する,
  en: View), matching the existing `button_edit_item` naming (S031).
- Unchanged: the "register" button when no article exists, no button for
  non-authors (including admins, since `editable_by?` has no admin exception),
  the post-create/update redirect to the entry page, and the edit button on the
  article show page (S031).

## Decisions and rejected alternatives

- **Reuse `AdventCalendarItem#published?` as-is** — the article show page uses
  the same method, so the button can never lead to a redirect to top. It
  includes the publish day itself and uses Tokyo time (`config.time_zone`). The
  entry page has already passed `check_visibility`, so board visibility is
  satisfied too (S031).
- Rejected: `item.readable?(current_user)` (repeats the membership query for
  the same result); date comparison or a new helper in the view (two places
  for one rule) (S031).
- Rejected: showing both buttons — the spec says "instead of" (S031).
- Rejected: reusing `views.items._content.link_edit` for the label (shares a
  key between different meanings) (S031).

## Testing and docs

- Controller spec with `render_views` (ADR-0003); dates pinned with
  `allow(Time.zone).to receive(:today)` for the day before, the day of and the
  day after the publish date. No system-spec infrastructure exists, so none was
  added. No ADR was needed (S031).

Related: [Show Page Visibility](./show-page-visibility.md),
[User, Event, Slot and Article Authorization](./user-event-item-authorization.md),
[Views and Frontend](./views-and-frontend.md).
