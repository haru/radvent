---
title: Navbar Breadcrumb — Event Segment
type: decision
sources: [S034]
updated: 2026-10-25
---

# Navbar Breadcrumb — Event Segment

Feature `019-breadcrumb-event` (Issue #294) extends the navbar trail
"TOP / board name" with the event, so article, slot and event pages link back
to the calendar in one click. The trail lives in `#top-menu` of
`app/views/layouts/application.html.haml`; the board name shows only for user
boards (S034).

## Decisions

- **Dedicated `@breadcrumb_event`**: assigned in each controller's
  `find_board` next to `@board`; the layout reads only this variable. Because
  `find_board` is declared after the authorization filters, 404 and 403 pages
  never print the event name — the same mechanism that hides the board name
  (see [Board Visibility on Show Pages](./show-page-visibility.md)) (S034).
- **Why not read `@event` in the layout**: a user who may see an event but not
  join it would see its name on the 403 from
  `AdventCalendarItemsController#check_slot_creation_authorization` (which
  assigns `@event` before `render_forbidden`), and the unsaved `Event.new` on
  event new/create would appear (S034).
- **Event source per screen**: items use `@item.advent_calendar_item.event`
  (or `@advent_calendar_item.event` for new/create/preview_new); slots use
  `@advent_calendar_item.event` (or `@event` for new/create); events use
  `@event`. Event new/create show no event segment (S034).
- **Saved title, not the form value**: helper `persisted_event_title(event)`
  returns `title_in_database.presence || event.title`, mirroring
  `persisted_event_name`; the link uses the existing `event_page_path`. After
  a failed `EventsController#update` the trail still shows the saved title
  (S034).
- **Current page**: when `current_page?(event_page_path(@breadcrumb_event))`
  is true the name is a plain `%span` with `aria-current="page"`, not a link.
  Chosen over `controller_name`/`action_name` checks or an extra flag. It only
  matches GET, so a failed PATCH on the edit page renders a link (S034).
- **Long titles**: one line with CSS ellipsis (`min-width: 0` on the wrapper,
  `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` on the
  name) plus a `title` attribute with the full text; rules live in
  `partials/welcome.scss`. Existing board-name truncation is untouched (S034).
- **Rejected**: a layout-side `@event || @advent_calendar_item&.event || …`
  chain; deriving `@board` from the event (boards screens have no event);
  breadcrumb gems (gretel, breadcrumbs_on_rails); `@event.reload` copies;
  server-side truncation; browser system specs (S034).
- **No ADR**: it applies the existing "assign layout values after the
  authorization filters" rule (S034).

## Testing

Layout view spec (order, links for TOP vs user boards, `title`,
`aria-current`, nil fallback with `current_page?` stubbed), helper spec for
unsaved changes, and `render_views` controller specs (ADR-0003) covering every
screen plus 404/403, including the slot-creation 403. Ellipsis is checked
manually via quickstart.md (S034).

See also [Views and Frontend](./views-and-frontend.md).
