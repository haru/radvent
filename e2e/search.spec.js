import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs, openPage } from './support/accounts.js'
import { pastEventPeriod } from './support/dates.js'
import { createBoard, createEvent, joinDay, writeArticle } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

const publicBoard = { boardId: 'e2e-search-pub', name: 'E2E 検索公開ボード', visibility: '公開' }
const privateBoard = { boardId: 'e2e-search-priv', name: 'E2E 検索非公開ボード', visibility: '非公開' }
const publicEvent = { name: 'e2e-search-pub-ev', title: 'E2E 検索公開イベント', ...pastEventPeriod() }
const privateEvent = { name: 'e2e-search-priv-ev', title: 'E2E 検索非公開イベント', ...pastEventPeriod() }
const eventPath = (board, event) => `/boards/${board.boardId}/events/${event.name}`

// Words that appear nowhere else in the E2E data.
const publicWord = 'srchpubword'
const privateWord = 'srchprivword'
const manyWord = 'srchmanyword'
const firstTitle = 'E2E 検索 公開記事'

const searchForm = (page) => page.locator('#navTopMenu form[role=search]')
const searchFor = async (page, text) => {
  await searchForm(page).getByRole('searchbox').fill(text)
  await searchForm(page).getByRole('searchbox').press('Enter')
}
const results = (page) => page.locator('ol.search-results li.search-result')

test.describe.serial('記事検索', () => {
  test.beforeEach(async () => {
    clearJsErrors()
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('準備: 公開ボード・非公開ボードに記事を用意する', async ({ browser }) => {
    test.setTimeout(240000)
    const { page } = await openAs(browser, accounts.bob)
    await createBoard(page, publicBoard)
    await createEvent(page, publicEvent)
    await joinDay(page, eventPath(publicBoard, publicEvent), 1)
    await writeArticle(page, firstTitle, `本文に ${publicWord} を含む。長い本文のあとに Ruby Rails`)
    await createBoard(page, privateBoard)
    await createEvent(page, privateEvent)
    await joinDay(page, eventPath(privateBoard, privateEvent), 1)
    await writeArticle(page, 'E2E 検索 非公開記事', `${privateWord} を含む非公開の本文`)
    // 21 matching articles so that the results need a second page (day 1 is already taken above).
    await joinDay(page, eventPath(publicBoard, publicEvent), 2)
    await writeArticle(page, `${manyWord} 2`, `${manyWord} body`)
    for (let day = 3; day <= 22; day += 1) {
      await joinDay(page, eventPath(publicBoard, publicEvent), day)
      await writeArticle(page, `${manyWord} ${day}`, `${manyWord} body`)
    }
  })

  test('R-1 タイトルバーから検索すると、情報付きの結果が強調表示され、検索窓に語が残る', async ({ browser }) => {
    const { page } = await openPage(browser)
    watchJsErrors(page.context())
    await page.goto('/')
    await searchFor(page, publicWord)
    await expect(page).toHaveURL(new RegExp(`/search\\?q=${publicWord}$`))
    await expect(results(page)).toHaveCount(1)
    const row = results(page).first()
    await expect(row).toContainText(firstTitle)
    await expect(row).toContainText('e2e-bob')
    await expect(row).toContainText(publicBoard.name)
    await expect(row).toContainText(publicEvent.title)
    await expect(row.locator('.search-result-date')).toContainText('年')
    await expect(row.locator('.search-result-excerpt mark')).toHaveText(publicWord)
    await expect(searchForm(page).getByRole('searchbox')).toHaveValue(publicWord)
    await expect(page.locator('.search-count')).toContainText('1件')
  })

  test('R-2 結果のタイトルをクリックすると記事ページが開く', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto(`/search?q=${publicWord}`)
    await results(page).first().getByRole('link', { name: firstTitle }).click()
    await expect(page).toHaveURL(/\/items\/\d+$/)
    await expect(page.getByRole('heading', { name: firstTitle })).toBeVisible()
  })

  test('R-3 非公開ボードの記事は、未ログインや非メンバーでは出ず、オーナーでは出る', async ({ browser }) => {
    const guest = await openPage(browser)
    await guest.page.goto(`/search?q=${privateWord}`)
    await expect(guest.page.locator('.search-notice')).toContainText('該当する記事が見つかりませんでした')
    await expect(results(guest.page)).toHaveCount(0)
    await expect(guest.page.locator('.search-count')).toHaveCount(0)

    const alice = await openAs(browser, accounts.alice)
    await alice.page.goto(`/search?q=${privateWord}`)
    await expect(results(alice.page)).toHaveCount(0)

    const owner = await openAs(browser, accounts.bob)
    await owner.page.goto(`/search?q=${privateWord}`)
    await expect(results(owner.page)).toHaveCount(1)
  })

  test('R-4 該当なしと空入力にはそれぞれ案内が出る', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto('/')
    await searchFor(page, 'zzznomatchzzz')
    await expect(page.locator('.search-notice')).toContainText('該当する記事が見つかりませんでした')
    await expect(searchForm(page).getByRole('searchbox')).toHaveValue('zzznomatchzzz')
    await page.goto('/search?q=')
    await expect(page.locator('.search-notice')).toContainText('検索するキーワードを入力してください')
  })

  test('R-5 21件以上は「もっと見る」で続きが同じ画面に追加され、最終ページでボタンが消える', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto(`/search?q=${manyWord}`)
    await expect(page.locator('.search-count')).toContainText('21件')
    await expect(results(page)).toHaveCount(20)
    await page.getByRole('link', { name: 'もっと見る' }).click()
    await expect(results(page)).toHaveCount(21)
    await expect(page.getByRole('link', { name: 'もっと見る' })).toHaveCount(0)
    await expect(page).toHaveURL(new RegExp(`/search\\?q=${manyWord}$`))
  })

  test('R-6 スマートフォン幅でも、メニューを開けば検索でき、横スクロールが出ない', async ({ browser }) => {
    const { page } = await openPage(browser, { viewport: { width: 375, height: 700 } })
    await page.goto('/', { waitUntil: 'networkidle' })
    await expect(searchForm(page)).toBeHidden()
    await page.getByRole('button', { name: 'Toggle navigation' }).click()
    await expect(searchForm(page)).toBeVisible()
    await searchFor(page, publicWord)
    await expect(results(page)).toHaveCount(1)
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth)
    expect(overflow).toBe(false)
  })

  test('R-7 ダークテーマでも結果と強調が読める', async ({ browser }) => {
    const { page } = await openPage(browser)
    await page.goto(`/search?q=${publicWord}`)
    await page.evaluate(() => document.documentElement.setAttribute('data-theme', 'dark'))
    const mark = results(page).first().locator('.search-result-excerpt mark')
    await expect(mark).toBeVisible()
    expect(await mark.evaluate((el) => window.getComputedStyle(el).fontWeight)).toMatch(/^(700|bold|[89]00)$/)
    const colors = await results(page)
      .first()
      .evaluate((el) => ({ text: window.getComputedStyle(el).color, page: window.getComputedStyle(document.body).backgroundColor }))
    expect(colors.text).not.toBe(colors.page)
  })
})
