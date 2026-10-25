import { Buffer } from 'node:buffer'
import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs, openPage } from './support/accounts.js'
import { pastEventPeriod } from './support/dates.js'
import { fillMarkdown } from './support/editor.js'
import { createBoard, createEvent, dayCell, joinDay, writeArticle } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

const board = { boardId: 'e2e-articles', name: 'E2E 記事ボード', visibility: '公開' }
const event = { name: 'e2e-articles-event', title: 'E2E 記事のイベント', ...pastEventPeriod() }
const eventPath = `/boards/${board.boardId}/events/${event.name}`

// Paths collected while the scenarios run, keyed by day.
const slots = {}
const items = {}
const currentPath = (page) => new URL(page.url()).pathname

// Joins the day as the page's user, writes the article and remembers the paths of the slot and the article.
async function publish(page, day, title, body) {
  await joinDay(page, eventPath, day)
  slots[day] = currentPath(page)
  await writeArticle(page, title, body)
  await page.getByRole('link', { name: '投稿記事を表示する' }).click()
  await expect(page).toHaveURL(/\/items\/\d+$/)
  items[day] = currentPath(page)
}

test.describe.serial('枠と記事', () => {
  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('準備: alice の公開ボードにイベントと2つの記事を用意する', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    await createBoard(page, board)
    await createEvent(page, event)
    await publish(page, 5, 'E2E 五日目の記事', '五日目の本文')
    await publish(page, 6, 'E2E 六日目の記事', '六日目の本文')
  })

  test('E-6 記事の前後ナビ: 前の日と次の日の記事へ移動できる', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto(items[6])
    await page.locator('.item-nav').first().getByRole('link', { name: 'E2E 五日目の記事' }).click()
    await expect(page).toHaveURL(new RegExp(`${items[5]}$`))
    await expect(page.locator('.item-show-header-title')).toHaveText('E2E 五日目の記事')
    await page.locator('.item-nav').first().getByRole('link', { name: 'E2E 六日目の記事' }).click()
    await expect(page).toHaveURL(new RegExp(`${items[6]}$`))
  })

  test('E-2 すでに使われている日には、他の人は参加登録できない', async ({ browser }) => {
    const bob = await openAs(browser, accounts.bob)
    await bob.page.goto(eventPath)
    await expect(dayCell(bob.page, 5)).toContainText(accounts.alice.name)
    await expect(dayCell(bob.page, 5).getByRole('link', { name: '参加登録' })).toHaveCount(0)

    // The join form of a taken day can still be reached by its address; saving it must be refused.
    const joinHref = await dayCell(bob.page, 7).getByRole('link', { name: '参加登録' }).getAttribute('href')
    const takenHref = joinHref.replace('date=7', 'date=5')
    await bob.page.goto(takenHref)
    await bob.page.getByRole('button', { name: '登録する' }).click()
    await expect(bob.page.locator('.alert-danger, #error_explanation, .has-error').first()).toBeVisible()
    await bob.page.goto(eventPath)
    await expect(dayCell(bob.page, 5)).toContainText(accounts.alice.name)
    await expect(dayCell(bob.page, 5)).not.toContainText(accounts.bob.name)
  })

  test('E-3 公開前の枠は、名前とコメントを編集できる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await joinDay(page, eventPath, 8)
    const slotPath = currentPath(page)
    await page.getByRole('link', { name: '名前とコメントを編集する' }).click()
    await page.locator('#advent_calendar_item_user_name').fill('E2E 筆名')
    await page.locator('#advent_calendar_item_comment').fill('E2E 予告コメント')
    await page.getByRole('button', { name: '登録する' }).click()
    await expect(page).toHaveURL(new RegExp(`${slotPath}$`))
    await expect(page.getByText('E2E 筆名')).toBeVisible()
    await expect(page.getByText('E2E 予告コメント')).toBeVisible()
    await page.goto(eventPath)
    await expect(dayCell(page, 8)).toContainText('E2E 筆名')
    await expect(dayCell(page, 8)).toContainText('E2E 予告コメント')
  })

  test('E-4 他人の枠と記事は編集できず(403)、管理者は編集できる', async ({ browser }) => {
    const bob = await openAs(browser, accounts.bob)
    const guest = await openPage(browser)
    for (const path of [slots[5], `${slots[5]}/edit`, `${items[5]}/edit`]) {
      expect((await bob.page.goto(path)).status(), `bob ${path}`).toBe(403)
    }
    // A guest is sent to the sign-in screen.
    for (const path of [slots[5], `${items[5]}/edit`]) {
      await guest.page.goto(path)
      await expect(guest.page).toHaveURL(/\/users\/sign_in$/)
    }
    const admin = await openAs(browser, accounts.admin)
    for (const path of [slots[5], `${slots[5]}/edit`, `${items[5]}/edit`]) {
      expect((await admin.page.goto(path)).status(), `admin ${path}`).toBe(200)
    }
  })

  test('E-7 Markdown: 見出し・リスト・コードが表示され、HTMLやスクリプトは実行されない', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    await publish(page, 9, 'E2E Markdown の記事', '')
    await page.goto(`${items[9]}/edit`)
    // The editor continues a list on Enter, so a single item keeps the typed text predictable.
    const body = [
      '## 小見出し', '', '- 項目A', '', '', '```ruby', 'puts "hello"', '```', '',
      '[安全なリンク](https://example.com/)', '[危険なリンク](javascript:window.__xss=1)', '',
      '<script>window.__xss = 1</script>', '<img src=x onerror="window.__xss=1">'
    ].join('\n')
    await fillMarkdown(page, body)
    await page.getByRole('button', { name: '登録する' }).click()
    await expect(page.getByText('記事が登録されています')).toBeVisible()

    await page.goto(items[9])
    const article = page.locator('#item-show')
    await expect(article.locator('h2')).toHaveText('小見出し')
    await expect(article.locator('li')).toHaveText(['項目A'])
    await expect(article.locator('pre code')).toContainText('puts "hello"')
    await expect(article.getByRole('link', { name: '安全なリンク' })).toHaveAttribute('href', 'https://example.com/')
    expect(await page.evaluate(() => window.__xss)).toBeUndefined()
    await expect(article.locator('script')).toHaveCount(0)
    await expect(article.locator('img[onerror]')).toHaveCount(0)
    const dangerous = article.getByRole('link', { name: '危険なリンク' })
    if (await dangerous.count()) {
      await expect(dangerous).not.toHaveAttribute('href', /^javascript:/i)
    }
  })

  test('E-5 画像をアップロードするとMarkdownに挿入され、記事に画像が表示される', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    await publish(page, 10, 'E2E 画像の記事', '')
    await page.goto(`${items[10]}/edit`)
    const png = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64'
    )
    const chooser = page.waitForEvent('filechooser')
    await page.locator('.editor-toolbar button.upload-image').click()
    await (await chooser).setFiles({ name: 'e2e.png', mimeType: 'image/png', buffer: png })
    await expect(page.locator('.CodeMirror')).toContainText('![')
    await page.getByRole('button', { name: '登録する' }).click()
    await expect(page.getByText('記事が登録されています')).toBeVisible()

    await page.goto(items[10])
    const image = page.locator('#item-show img')
    await expect(image).toHaveCount(1)
    await expect.poll(() => image.evaluate((img) => img.complete && img.naturalWidth)).toBeGreaterThan(0)
    // The image of a published article follows the visibility of the board.
    const src = await image.getAttribute('src')
    const guest = await openPage(browser)
    const response = await guest.page.goto(src)
    expect(response.status()).toBe(200)
  })
})
