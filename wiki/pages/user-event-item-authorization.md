---
title: User, Event, Slot and Article Authorization
type: decision
sources: [S027]
updated: 2026-10-24
---

# User, Event, Slot and Article Authorization

Feature `013-user-event-item-authorization` applied existing rules to places
that had none: the user-info edit screen, event creation, calendar-slot
(`AdventCalendarItem`) creation and update, and article (`Item`) creation and
update. No ADR was written, because it reuses `admin_user!`,
`Event.creatable_on?`, `Board#visible?` and `editable_by?` (S027). General
rules live in [Authorization](./authorization.md); the sibling comment feature
is [Comment Authorization](./comment-authorization.md).

## Decisions

- **User-info edit** (`users#edit_info`) joins the `admin_user!` filter, which is
  declared before `find_user`, so a non-admin gets the same 403 whether or not
  the user exists. Guests get 403, not a login redirect, as on the user list
  (S027).
- **Decide and write with one value.** The defect in event creation was that the
  authorization read `params[:board_id]` while the record was built from
  `event[board_id]`. Now one private method resolves the board (blank id means
  TOP); `new` reads only the top-level `board_id`, `create` only
  `event[board_id]`, and the event is attached to the resolved board. Rejected:
  accept both and answer 400 on mismatch (S027).
- **Hidden targets answer 404, visible-but-forbidden 403.** A board, event or
  slot the requester cannot see gets the uniform 404, so private content is not
  revealed (S027).
- **`Event#joinable?(user)`** is the single "may join" rule: false for guests,
  true for any signed-in user on the TOP board, otherwise
  `Event.creatable_on?`. It lives on the model, not in controllers (S027).
- **Slots and articles are built from the authorized object**
  (`@event.advent_calendar_items.build`, `Item.new(advent_calendar_item: …)`).
  `has_one#build_item` is avoided because it would replace an existing article
  (S027).
- **Parent keys leave strong params.** `event_id` and `advent_calendar_item_id`
  are no longer permitted on update (silently dropped, since
  `action_on_unpermitted_parameters` is unset), so a record cannot be moved
  (S027).
- **Article authorization** is `admin? || editable_by?`; legacy slots without an
  account match by display name. The publish date is not checked, so owners may
  write early (S027).
- **Uniqueness.** One article per slot (`Item` validation on top of the existing
  unique index) and one slot per date per event (`AdventCalendarItem`
  validation with `if: :will_save_change_to_date?`, so pre-existing duplicates
  can still update other fields). No DB index, so the rare race is accepted
  (S027).
- **Filter order.** The new `before_action`s run after `authenticate_user!` and
  before `find_board`, so a hidden target never reaches the layout (S027).

## Shipped differences from the research

> ⚠ conflict: S027 (R8) says slot `update` keeps a plain `render :edit`; the
> shipped code returns `unprocessable_content` (422) for failed slot updates and
> article create/update, because Turbo ignores a 200 form response.

> ⚠ conflict: S027 (R11) says the article form shows no error message; the
> shipped code adds an errors partial and localized "already has an article"
> text.

Also added after review: slot `date` must be present and within 1..31, and the
event controller assigns `@board` only after the visibility check passes, since
the 404 layout prints `@board.name` for user boards.

## Out of scope

Article preview (V-06) is still unauthorized and `preview_params` keeps
`advent_calendar_item_id`; "join" links are still shown to users who would get
403 (S027).
