import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs, openPage } from './support/accounts.js'
import { acceptNextDialog } from './support/dialog.js'
import { futureEventPeriod } from './support/dates.js'
import { createEvent } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

// This file runs after the other specs (file names are sorted): it edits and deletes dave, who the
// account scenarios of auth.spec.js no longer need then.
const userRow = (page, name) => page.getByRole('row', { name: new RegExp(name) })
const topEvent = { name: 'e2e-top-event', title: 'E2E TOP のイベント', ...futureEventPeriod() }

test.describe.serial('管理者の画面', () => {
  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('B-1 管理者以外には、ユーザー一覧もユーザー編集も開けず、設定メニューも出ない', async ({ browser }) => {
    const carol = await openAs(browser, accounts.carol)
    const guest = await openPage(browser)
    for (const viewer of [carol, guest]) {
      for (const path of ['/users', '/user/1/edit']) {
        const response = await viewer.page.goto(path)
        expect(response.status(), path).toBe(403)
        await expect(viewer.page.getByText('403 forbidden')).toBeVisible()
      }
    }
    await carol.page.goto('/')
    await expect(carol.page.locator('#navTopMenu').getByRole('link', { name: '設定' })).toHaveCount(0)
  })

  test('B-2 管理者はユーザー一覧を開け、検索で絞り込める', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.admin)
    await page.goto('/')
    await page.locator('#navTopMenu').getByRole('link', { name: '設定' }).click()
    await expect(page).toHaveURL(/\/users$/)
    for (const account of [accounts.admin, accounts.alice, accounts.bob, accounts.carol]) {
      await expect(page.getByRole('cell', { name: account.email })).toBeVisible()
    }
    await page.getByRole('searchbox').or(page.locator('input[type=search]')).first().fill(accounts.carol.name)
    await expect(page.getByRole('cell', { name: accounts.carol.email })).toBeVisible()
    await expect(page.getByRole('cell', { name: accounts.alice.email })).toHaveCount(0)
  })

  test('B-3 管理者はユーザーの名前と管理者権限を変更できる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.admin)
    await page.goto('/users')
    await page.getByRole('link', { name: accounts.dave.name }).click()
    await page.getByLabel('名前').fill('e2e-dave-edited')
    await page.getByLabel('管理者').check()
    await page.getByRole('button', { name: '更新する' }).click()
    await expect(page.getByLabel('名前')).toHaveValue('e2e-dave-edited')
    await expect(page.getByLabel('管理者')).toBeChecked()
    await page.goto('/users')
    await expect(userRow(page, 'e2e-dave-edited')).toContainText('true')
  })

  test('B-3 (入力エラー) 不正なメールアドレスは保存されず、エラーが表示される', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.admin)
    await page.goto('/users')
    await userRow(page, 'e2e-dave-edited').getByRole('link').click()
    await page.getByLabel('メールアドレス').fill('not-an-email')
    await page.locator('form[action^="/user/"]').evaluate((form) => form.setAttribute('novalidate', ''))
    await page.getByRole('button', { name: '更新する' }).click()
    await expect(page.locator('.invalid-feedback, .alert-danger, .help-block').first()).toBeVisible()
    await expect(page.locator('#admin-menu')).toBeVisible()
    await page.goto('/users')
    await expect(page.getByRole('cell', { name: accounts.dave.email })).toBeVisible()
  })

  test('B-4 管理者はユーザーを削除でき、確認ダイアログで進める', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.admin)
    await page.goto('/users')
    await userRow(page, 'e2e-dave-edited').getByRole('link').click()
    const confirmed = acceptNextDialog(page)
    await page.getByRole('button', { name: '削除' }).click()
    await confirmed
    await expect(page).toHaveURL(/\/users$/)
    await expect(page.getByRole('cell', { name: accounts.dave.email })).toHaveCount(0)
    await expect(page.getByRole('cell', { name: accounts.carol.email })).toBeVisible()
  })

  test('B-5 管理者は TOP にイベントを作成・編集・削除できる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.admin)
    await page.goto('/')
    await createEvent(page, topEvent)
    await page.goto('/')
    await expect(page.locator('a.event-card', { hasText: topEvent.title })).toBeVisible()

    await page.goto(`/events/${topEvent.name}/edit`)
    await page.getByLabel('説明').fill('E2E TOP の説明')
    await page.getByRole('button', { name: '更新する' }).click()
    await expect(page.getByText('E2E TOP の説明')).toBeVisible()

    await page.goto(`/events/${topEvent.name}/edit`)
    const confirmed = acceptNextDialog(page)
    await page.getByRole('button', { name: '削除' }).click()
    await confirmed
    await expect(page).toHaveURL((url) => url.pathname === '/')
    await expect(page.locator('a.event-card', { hasText: topEvent.title })).toHaveCount(0)
  })
})
