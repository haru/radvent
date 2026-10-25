import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs, openPage } from './support/accounts.js'
import { pastEventPeriod } from './support/dates.js'
import { createBoard, createEvent, joinDay, writeArticle } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

const board = { boardId: 'e2e-comments', name: 'E2E コメントボード', visibility: '公開' }
const event = { name: 'e2e-comments-event', title: 'E2E コメントのイベント', ...pastEventPeriod() }
const eventPath = `/boards/${board.boardId}/events/${event.name}`

let itemPath
const comments = (page) => page.locator('#comments_list')
const post = async (page, name, body) => {
  await page.getByLabel('お名前を入力してください').fill(name)
  await page.getByLabel('コメントを入力してください').fill(body)
  await page.getByRole('button', { name: '投稿する' }).click()
}

test.describe.serial('コメントといいねの権限', () => {
  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('準備: alice の公開ボードに記事を1つ用意する', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    await createBoard(page, board)
    await createEvent(page, event)
    await joinDay(page, eventPath, 1)
    await writeArticle(page, 'E2E コメント用の記事', 'コメントを付けるための本文')
    await page.getByRole('link', { name: '投稿記事を表示する' }).click()
    await expect(page).toHaveURL(/\/items\/\d+$/)
    itemPath = new URL(page.url()).pathname
  })

  // Comments are rendered as Markdown and sanitized (DOMPurify): harmless tags stay, scripts and handlers go.
  test('F-2 コメントのスクリプトは実行されず、名前はそのまま文字として表示される', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto(itemPath)
    await post(page, '<i>読者</i>', '<b id="e2e-bold">太字</b><img src=x onerror="window.__xss=1"><script>window.__xss=1</script>')
    await expect(comments(page)).toContainText('<i>読者</i>')
    await expect(comments(page).locator('#e2e-bold')).toHaveText('太字')
    await expect(comments(page).locator('img[onerror], script')).toHaveCount(0)
    expect(await page.evaluate(() => window.__xss)).toBeUndefined()
  })

  test('F-2 (空のコメント) 名前も本文も空のコメントは投稿されない', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto(itemPath)
    const before = await comments(page).locator('.comment').count()
    await post(page, '', '')
    await expect(page.locator('#comment_errors .alert-danger')).toBeVisible()
    expect(await comments(page).locator('.comment').count()).toBe(before)
  })

  test('F-3 コメントを削除できるのはボードの管理者だけで、ゲストや他のユーザーには削除ボタンが出ない', async ({ browser }) => {
    const guest = await openPage(browser)
    const bob = await openAs(browser, accounts.bob)
    const carol = await openAs(browser, accounts.carol)
    for (const viewer of [guest, bob, carol]) {
      await viewer.page.goto(itemPath)
      await expect(comments(viewer.page)).toContainText('読者')
      await expect(comments(viewer.page).getByRole('button', { name: '削除' })).toHaveCount(0)
    }
    const admin = await openAs(browser, accounts.admin)
    await admin.page.goto(itemPath)
    await expect(comments(admin.page).getByRole('button', { name: '削除' }).first()).toBeVisible()
  })

  test('F-4 ゲストにはいいねのボタンが出ず、数だけが見える', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto(itemPath)
    await expect(page.locator('#like-button')).toHaveCount(0)
    await expect(page.locator('#like-buttons')).toBeVisible()
  })

  test('F-5 コメントに名前を入れる欄は、ログイン中なら自分の名前が初期値になる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto(itemPath)
    await expect(page.getByLabel('お名前を入力してください')).toHaveValue(accounts.bob.name)
  })
})
