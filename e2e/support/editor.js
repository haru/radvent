// EasyMDE hides the original textarea, so type into the CodeMirror editor like a user would.
export async function fillMarkdown(page, text, { replace = false } = {}) {
  await page.locator('.CodeMirror').click()
  if (replace) {
    await page.keyboard.press('ControlOrMeta+A')
  }
  await page.keyboard.type(text)
}
