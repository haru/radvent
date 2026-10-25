// Accepts the next confirm dialog. Await the returned promise after the click that opens the
// dialog, so a missing dialog fails the test instead of being ignored.
export function acceptNextDialog(page) {
  return page.waitForEvent('dialog').then((dialog) => dialog.accept())
}
