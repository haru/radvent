---
title: Board Deletion — ID Confirmation & Dialog
type: decision
sources: [S013, S014]
updated: 2026-09-16
---

# Board Deletion — ID Confirmation & Dialog

Feature `006-board-delete-id-confirm` (branch, 2026-09-16) fixes a gap where
the board-edit screen displayed a "type the board ID to confirm deletion"
message with no actual input field — the delete button removed the board
immediately on click (S013).

## Confirmation mechanism

`Board` gains a `board_id_match?(input)` instance method: normalizes the
input the same way `normalize_board_id` normalizes stored IDs (downcase +
strip) and compares to `board_id` (S013). The logic lives on the model, not
inline in the controller, so it's reusable from other call sites (e.g. a
future API) and keeps normalization rules in one place (S013).

`BoardsController#destroy` calls `board_id_match?(params[:confirm_board_id])`
before `@board.destroy`; on mismatch it does **not** delete — it redirects to
`edit_board_path` with an explicit `alert` flash
(`t('boards.edit.delete_id_mismatch')`), never silently ignoring the failed
check (S013; matches the project's explicit-error-handling convention). This
check runs after, and is independent from, the existing `check_deletability`
authorization gate — see
[Controllers and Routing](./controllers-and-routing.md#authorization-filters)
(S013).

## Client-side UX

A new Stimulus controller, `board_delete_confirmation_controller`
(`input`/`submit` targets, an `expectedId` value), disables the delete button
by default and enables it only once the typed value matches the board's ID in
real time — see
[JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md) for where
it sits among the other controllers (S013). The delete form moved from a
single-button `button_to` to a `form_with` block, since `button_to` can't
render an input field alongside its submit button (S013).

## Browser-native confirm dialog: kept, not replaced

Initial design removed the existing `data: { "turbo-confirm": ... }` browser
confirm dialog, treating the typed-ID confirmation as its GitHub-style
replacement (S013). A post-implementation review flagged this as a UX
regression, and the decision was reversed: the native dialog is now kept
*alongside* the typed-ID gate as a second, independent safeguard — clicking
the (now-enabled) delete button still triggers the standard browser confirm
before the request is sent (S014).

## Defense in depth

The client-side disable/enable and the browser confirm dialog are both
bypassable (disabled JS, direct HTTP requests), so `board_id_match?` is also
checked server-side — this is the actual authority. If JavaScript is off, the
button renders without the real-time disable/enable behavior, but a
mismatched or missing `confirm_board_id` is still rejected server-side
(S013). No JS unit-test or system-test infrastructure exists in this project,
so the client-side real-time disable/enable is verified by a manual
`quickstart.md` walkthrough rather than automated tests — the server-side
check is what carries the actual security guarantee (S013).

See [Domain Model](./domain-model.md#authorization) for `Board#deletable?`
and the authorization gate this feature builds on.
