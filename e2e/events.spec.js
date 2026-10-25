import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs, openPage } from './support/accounts.js'
import { acceptNextDialog } from './support/dialog.js'
import { pastEventPeriod } from './support/dates.js'
import { createBoard, createEvent, dayCell, joinDay } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

// A limited-access board: everybody can look, only alice (owner) and bob (member) can post.
const board = { boardId: 'e2e-events', name: 'E2E イベントボード', visibility: '限定公開' }
const boardPath = `/boards/${board.boardId}`
const period = pastEventPeriod()
const alicesEvent = { name: 'e2e-alice-event', title: 'E2E alice のイベント', ...period }
const bobsEvent = { name: 'e2e-bob-event', title: 'E2E bob のイベント', ...period }
const alicesEventPath = `${boardPath}/events/${alicesEvent.name}`

const eventCard = (page, title) => page.locator('a.event-card', { hasText: title })

test.describe.serial('イベントとカレンダー', () => {
  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('D-3 カレンダー: 曜日見出しと週ごとの7列があり、期間内の日だけ参加登録できる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    await createBoard(page, board)
    await page.goto(`${boardPath}/board_memberships`)
    await page.getByPlaceholder('ユーザー名またはメールアドレス').fill(accounts.bob.name)
    await page.getByRole('button', { name: 'メンバーを追加' }).click()
    await expect(page.getByText('メンバーを追加しました')).toBeVisible()

    await page.goto(boardPath)
    await createEvent(page, alicesEvent)
    await page.goto(alicesEventPath)
    await expect(page.locator('table.advent-calendar-calendar thead th')).toHaveText(['日', '月', '火', '水', '木', '金', '土'])
    for (const row of await page.locator('table.advent-calendar-calendar tbody tr').all()) {
      await expect(row.locator('td')).toHaveCount(7)
    }
    await expect(page.getByRole('link', { name: '参加登録' })).toHaveCount(period.lastDay)

    await joinDay(page, alicesEventPath, 3)
    await page.goto(boardPath)
    const bar = eventCard(page, alicesEvent.title).locator('.progress-bar')
    await expect(bar).toHaveAttribute('aria-valuenow', '1')
    await expect(bar).toHaveAttribute('aria-valuemax', String(period.lastDay))
  })

  test('D-2 イベントの入力エラー: 名前やタイトルの重複、月をまたぐ期間、不正な名前では保存されない', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    const submit = async (event, { end = event.end } = {}) => {
      await page.goto(`/events/new?board_id=${await boardRecordId(page)}`)
      await page.getByLabel('名', { exact: true }).fill(event.name)
      await page.getByLabel('タイトル').fill(event.title)
      await page.getByLabel('開始日').fill(event.start)
      await page.getByLabel('終了日').fill(end)
      await page.getByRole('button', { name: '登録する' }).click()
    }
    const [year, month] = period.start.split('-')

    await test.step('名前の重複', async () => {
      await submit({ ...alicesEvent, title: 'E2E 別のタイトル' })
      await expect(page.locator('.alert-danger')).toBeVisible()
    })
    await test.step('タイトルの重複', async () => {
      await submit({ ...alicesEvent, name: 'e2e-other-name' })
      await expect(page.locator('.alert-danger')).toBeVisible()
    })
    await test.step('開始日と終了日が別の月', async () => {
      const nextMonth = Number(month) === 12 ? `${Number(year) + 1}-01-01` : `${year}-${String(Number(month) + 1).padStart(2, '0')}-01`
      await submit({ ...alicesEvent, name: 'e2e-two-months', title: 'E2E 二か月' }, { end: nextMonth })
      await expect(page.locator('.alert-danger')).toBeVisible()
    })
    await test.step('使えない文字を含む名前', async () => {
      const [response] = await Promise.all([
        page.waitForResponse((r) => r.request().method() === 'POST' && r.url().endsWith('/events')),
        submit({ ...alicesEvent, name: 'Bad Name!', title: 'E2E 不正な名前' })
      ])
      expect(response.status()).toBe(422)
      await expect(page.locator('.alert-danger')).toBeVisible()
    })
    await page.goto(boardPath)
    await expect(eventCard(page, 'E2E 二か月')).toHaveCount(0)
    await expect(eventCard(page, 'E2E 不正な名前')).toHaveCount(0)
  })

  test('D-4 イベントの作成・編集・削除の権限: メンバーは自分のイベントだけ編集でき、他の人はできない', async ({ browser }) => {
    const bob = await openAs(browser, accounts.bob)
    await bob.page.goto(boardPath)
    await createEvent(bob.page, bobsEvent)

    const carol = await openAs(browser, accounts.carol)
    const guest = await openPage(browser)
    for (const viewer of [carol, guest]) {
      await viewer.page.goto(boardPath)
      await expect(viewer.page.getByRole('link', { name: 'イベントを作成' })).toHaveCount(0)
    }
    const boardRecord = await boardRecordId(bob.page)
    expect((await carol.page.goto(`/events/new?board_id=${boardRecord}`)).status()).toBe(403)

    const forbidden = [
      [bob.page, `${alicesEventPath}/edit`], [carol.page, `${alicesEventPath}/edit`],
      [carol.page, `${boardPath}/events/${bobsEvent.name}/edit`], [guest.page, `${alicesEventPath}/edit`]
    ]
    for (const [page, path] of forbidden) {
      expect((await page.goto(path)).status(), path).toBe(403)
    }

    // alice owns the board, but not bob's event.
    const alice = await openAs(browser, accounts.alice)
    expect((await alice.page.goto(`${boardPath}/events/${bobsEvent.name}/edit`)).status()).toBe(403)

    expect((await bob.page.goto(`${boardPath}/events/${bobsEvent.name}/edit`)).status()).toBe(200)
  })

  test('D-6 ボードを持たない旧形式のURLは、ボード付きのURLへ転送される', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.carol)
    await page.goto(`/events/${alicesEvent.name}`)
    await expect(page).toHaveURL(new RegExp(`${alicesEventPath}$`))
    await expect(page.getByRole('heading', { name: alicesEvent.title })).toBeVisible()
  })

  test('D-5 イベントを削除すると、確認のあとボードから消え、URLも開けなくなる', async ({ browser }) => {
    const bob = await openAs(browser, accounts.bob)
    const bobsPath = `${boardPath}/events/${bobsEvent.name}`
    await joinDay(bob.page, bobsPath, 4)
    await bob.page.goto(`${bobsPath}/edit`)
    const confirmed = acceptNextDialog(bob.page)
    await bob.page.getByRole('button', { name: '削除' }).click()
    await confirmed
    await expect(bob.page).toHaveURL(new RegExp(`${boardPath}$`))
    await expect(eventCard(bob.page, bobsEvent.title)).toHaveCount(0)
    expect((await bob.page.goto(bobsPath)).status()).toBe(404)
  })

  test('D-7 参加登録済みの日は他の人には「参加登録」が出ず、作者名が出る', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto(alicesEventPath)
    await expect(dayCell(page, 3)).toContainText(accounts.alice.name)
    await expect(dayCell(page, 3).getByRole('link', { name: '参加登録' })).toHaveCount(0)
    await expect(dayCell(page, 3).getByRole('link', { name: '編集' })).toHaveCount(0)
    await expect(dayCell(page, 4).getByRole('link', { name: '参加登録' })).toBeVisible()
  })
})

// The numeric id of the board, which the event form needs (the page links to it from "create event").
async function boardRecordId(page) {
  await page.goto(boardPath)
  const href = await page.getByRole('link', { name: 'イベントを作成' }).getAttribute('href')
  return new URL(href, page.url()).searchParams.get('board_id')
}
