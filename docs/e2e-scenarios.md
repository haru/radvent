# E2E scenario list

Every screen of the app and the scenarios that exercise it. The main journey
(`e2e/user-journey.spec.js`, US2–US5) stays as it is; the scenarios below extend it
(`e2e/*.spec.js`). How to run them: [e2e-testing.md](e2e-testing.md).

Legend: ✅ covered by the main journey, 🆕 added by the extended specs.

## 1. Screens

| # | Screen | Path |
|---|--------|------|
| S1 | TOP (board of the system) | `/` |
| S2 | Sign-in | `/users/sign_in` |
| S3 | Sign-up | `/users/sign_up` |
| S4 | Password reset request / edit | `/users/password/new`, `/users/password/edit` |
| S5 | My page (account edit, theme, cancel account) | `/users/edit` |
| S6 | Board list | `/boards` |
| S7 | Board create / edit / delete | `/boards/new`, `/boards/:id/edit` |
| S8 | Board members | `/boards/:id/board_memberships` |
| S9 | Board (event cards, other boards) | `/boards/:id` |
| S10 | Event create / edit / delete | `/events/new`, `…/events/:name/edit` |
| S11 | Event calendar | `/events/:name`, `/boards/:id/events/:name` |
| S12 | Slot join / edit / delete | `/advent_calendar_items/*` |
| S13 | Article create / edit / preview | `/items/new`, `/items/:id/edit` |
| S14 | Article (comments, likes, prev / next) | `/items/:id` |
| S15 | Admin: user list / edit / delete | `/users`, `/user/:id/edit` |
| S16 | Error pages (403, 404) | — |

## 2. Scenarios

### A. Accounts (`e2e/auth.spec.js`) — S2, S3, S4, S5

| ID | Scenario |
|----|----------|
| A-1 ✅ | Sign up, log in, log out, wrong password (US2) |
| A-2 🆕 | Sign-in screen links to sign-up and password reset; header shows the guest menu |
| A-3 🆕 | Sign-up with a taken e-mail and a mismatching confirmation shows the errors and creates no account |
| A-4 🆕 | Signed-in users are redirected away from the sign-in and sign-up screens |
| A-5 🆕 | Password reset request: malformed e-mail is rejected, unknown and known e-mails get the same notice |
| A-6 🆕 | My page: changing the name needs the current password; with it the header shows the new name |
| A-7 🆕 | My page: changing the password, then logging in with the new one only |
| A-8 🆕 | Theme switch (light / dark / system) is applied to the page and survives a reload |
| A-9 🆕 | Cancel my account removes the account and ends the session |
| A-10 🆕 | Guests are sent to the sign-in screen from board list / article form / slot form |

### B. Administration (`e2e/admin.spec.js`) — S15

| ID | Scenario |
|----|----------|
| B-1 🆕 | A non-admin gets 403 on the user list and the user edit screen; the settings menu is hidden |
| B-2 🆕 | Admin sees the settings menu and the user list |
| B-3 🆕 | Admin edits a user (name, admin flag); a malformed e-mail is rejected |
| B-4 🆕 | Admin deletes a user after the confirmation dialog; the user is gone from the list |
| B-5 🆕 | Admin creates, edits and deletes an event on the TOP board |

### C. Boards (`e2e/boards.spec.js`) — S6–S9

| ID | Scenario |
|----|----------|
| C-1 ✅ | Create, edit a board; add a member (US3) |
| C-2 🆕 | Board form errors: empty id/name, malformed id, taken id |
| C-3 🆕 | Visibility: public / protected / private boards for owner, member, other user and guest |
| C-4 🆕 | Members: add by e-mail, unknown user, duplicate, remove (the confirmation names the member); the "back to board settings" link goes to the settings page; member rows show user / envelope / trash icons |
| C-4b 🆕 | Member search: candidates from 2 characters (name or e-mail, any case), pick by mouse (confirm with the add button) or by keyboard only (confirm with Enter), editing after picking drops the pick, members and the owner are not offered, no-match message. IME composition is checked by hand (quickstart #13) |
| C-4c 🆕 | Member search behaviour: debounced single request, no request below 2 characters, ArrowUp / ArrowDown wrap and `aria-activedescendant`, typing after a highlight drops it, Esc and blur close the list and cancel a pending search, a stale response never overwrites a newer one, IME composition (no search while composing, one on end, composing Enter picks nothing), a Turbo-restored page works, 429 / 500 / 403 / 404 / non-HTML / network failure / expired session each show their own message |
| C-5 🆕 | Board list shows only own boards; empty state; the explanation of what a board is is always shown; each row has a gear-icon "設定" button; a guest or other user cannot edit a board (403) |
| C-6 🆕 | Public boards are listed under "other boards" on the TOP |
| C-7 🆕 | Delete a board: wrong id is refused, the right id deletes it and the board is 404 afterwards |
| C-8 🆕 | Unknown board / event gives the 404 page |

### D. Events and calendar (`e2e/events.spec.js`) — S10, S11

| ID | Scenario |
|----|----------|
| D-1 ✅ | Create / edit an event, calendar cells (US3) |
| D-2 🆕 | Event form errors: taken name, end date before start date |
| D-3 🆕 | Calendar: weekday header, only days of the period have join buttons, progress count after joining |
| D-4 🆕 | Only the owner can create / edit / delete events on a user board (403 for members / others) |
| D-5 🆕 | Delete an event: confirmation dialog, event gone from the board |

### E. Slots and articles (`e2e/articles.spec.js`) — S12–S14

| ID | Scenario |
|----|----------|
| E-1 ✅ | Join, write, preview, edit, delete (US4) |
| E-2 🆕 | A taken day cannot be joined by someone else; joining needs an author name |
| E-3 🆕 | Edit a slot (name, comment) before publishing |
| E-4 🆕 | Another user cannot edit someone's slot or article (403); an admin can |
| E-5 🆕 | Image upload in the editor inserts markdown and the image is served |
| E-6 🆕 | Previous / next navigation between articles |
| E-7 🆕 | Markdown rendering: code block, list, link, HTML is escaped |

### F. Comments and likes (`e2e/comments.spec.js`) — S14

| ID | Scenario |
|----|----------|
| F-1 ✅ | Post / delete a comment, like / unlike (US5) |
| F-2 🆕 | Empty comment is not posted; HTML in a comment is escaped |
| F-3 🆕 | A guest and an unrelated user cannot delete comments; the like button sends guests to sign-in |
