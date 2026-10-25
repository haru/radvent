import { test, expect } from '@playwright/test'
import {
  accounts, closeOpenedContexts, login, logout, openAs, openPage, submitLogin, userMenu
} from './support/accounts.js'
import { acceptNextDialog, dismissNextDialog } from './support/dialog.js'
import { fillSignUp } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

const guestMenu = (page) => page.locator('#top-menu')
const updateButton = (page) => page.locator('form[action="/users"] input[type=submit]')

test.describe.serial('アカウント', () => {
  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('A-2 ログイン画面から登録とパスワード再発行へ移動できる', async ({ page }) => {
    await page.goto('/')
    await expect(guestMenu(page).getByRole('link', { name: '新規登録' })).toBeVisible()
    await expect(guestMenu(page).getByRole('link', { name: 'ログイン' })).toBeVisible()
    await expect(guestMenu(page).getByRole('link', { name: 'ログアウト' })).toHaveCount(0)

    await page.getByRole('link', { name: 'ログイン' }).click()
    await page.locator('div.container').getByRole('link', { name: 'アカウント登録' }).click()
    await expect(page).toHaveURL(/\/users\/sign_up$/)
    await page.locator('div.container').getByRole('link', { name: 'ログイン' }).click()
    await expect(page).toHaveURL(/\/users\/sign_in$/)
    await page.getByRole('link', { name: 'パスワードを忘れましたか?' }).click()
    await expect(page).toHaveURL(/\/users\/password\/new$/)
  })

  test('A-3 登録の入力エラー(重複メール・確認用パスワード不一致)で登録されない', async ({ page }) => {
    await fillSignUp(page, {
      email: accounts.alice.email, name: 'e2e-someone', password: 'password-1', confirmation: 'password-2'
    })
    await page.getByRole('button', { name: 'アカウント登録' }).click()
    await expect(page.locator('.alert-danger li')).toHaveCount(2)
    await expect(page.locator('.alert-danger')).toContainText('確認用パスワードとパスワードの入力が一致しません')
    await expect(page).toHaveURL(/\/users(\/sign_up)?$/)
    await expect(page.getByRole('link', { name: 'ログアウト' })).toHaveCount(0)
  })

  test('A-4 ログイン済みならログイン・登録・再発行の画面から TOP へ戻される', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    for (const path of ['/users/sign_in', '/users/sign_up', '/users/password/new']) {
      await page.goto(path)
      await expect(page).toHaveURL((url) => url.pathname === '/')
      await expect(page.getByText('すでにログインしています。')).toBeVisible()
    }
  })

  test('A-5 パスワード再発行: 形式不正は弾かれ、登録の有無で表示が変わらない', async ({ page }) => {
    await page.goto('/users/password/new')
    await page.getByLabel('メールアドレス').fill('not-an-email')
    // The browser's own e-mail validation would stop the submit; bypass it to reach the server.
    await page.locator('form[action="/users/password"]').evaluate((form) => form.setAttribute('novalidate', ''))
    await page.locator('form[action="/users/password"] input[type=submit]').click()
    await expect(page.locator('.alert-danger')).toBeVisible()

    const notices = []
    for (const email of ['nobody@e2e.example.com', accounts.bob.email]) {
      await page.goto('/users/password/new')
      await page.getByLabel('メールアドレス').fill(email)
      await page.locator('form[action="/users/password"] input[type=submit]').click()
      await expect(page.locator('.alert-success')).toBeVisible()
      notices.push(await page.locator('.alert-success').innerText())
    }
    expect(notices[0]).toBe(notices[1])
  })

  test('A-6 マイページ: 現在のパスワードなしでは名前を変更できない', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.dave)
    await page.goto('/users/edit')
    await page.getByLabel('名前').fill('e2e-dave-renamed')
    await updateButton(page).click()
    await expect(page.locator('.alert-danger')).toBeVisible()
    await page.goto('/')
    await expect(userMenu(page)).toHaveText(accounts.dave.name)

    await page.goto('/users/edit')
    await page.getByLabel('名前').fill('e2e-dave-renamed')
    await page.getByLabel('現在のパスワード').fill(accounts.dave.password)
    await updateButton(page).click()
    await expect(userMenu(page)).toHaveText('e2e-dave-renamed')
    await page.goto('/users/edit')
    await page.getByLabel('名前').fill(accounts.dave.name)
    await page.getByLabel('現在のパスワード').fill(accounts.dave.password)
    await updateButton(page).click()
    await expect(userMenu(page)).toHaveText(accounts.dave.name)
  })

  test('A-7 パスワードを変更すると、新しいパスワードでだけログインできる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.dave)
    const newPassword = 'dave-new-password'
    await page.goto('/users/edit')
    await page.getByLabel('パスワード', { exact: true }).fill(newPassword)
    await page.getByLabel('確認用パスワード').fill(newPassword)
    await page.getByLabel('現在のパスワード').fill(accounts.dave.password)
    await updateButton(page).click()
    await expect(page.locator('.alert-success')).toBeVisible()
    await expect(userMenu(page)).toHaveText(accounts.dave.name)

    await logout(page)
    await submitLogin(page, accounts.dave.email, accounts.dave.password)
    await expect(page.getByText('メールアドレスかパスワードが違う')).toBeVisible()
    await login(page, { ...accounts.dave, password: newPassword })
    accounts.dave.password = newPassword
  })

  test('A-8 テーマを切り替えると画面に反映され、再読み込みしても保たれる', async ({ page }) => {
    await login(page, accounts.dave)
    await page.goto('/users/edit')
    for (const [label, value] of [['Dark', 'dark'], ['Light', 'light'], ['システム設定', 'system']]) {
      await page.getByText(label, { exact: true }).click()
      await expect(page.locator('html')).toHaveAttribute('data-theme', value)
      await page.reload()
      await expect(page.locator('html')).toHaveAttribute('data-theme', value)
      await expect(page.locator(`#theme_${value}`)).toBeChecked()
    }
  })

  test('A-9 アカウントを削除すると、ログアウトされて同じ認証情報では入れない', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.eve)
    await page.goto('/users/edit')

    // Declining the confirmation sends nothing: the account stays.
    const dismissed = dismissNextDialog(page)
    await page.getByRole('button', { name: 'アカウント削除' }).click()
    await dismissed
    await page.reload()
    await expect(userMenu(page)).toHaveText(accounts.eve.name)

    const accepted = acceptNextDialog(page)
    await page.getByRole('button', { name: 'アカウント削除' }).click()
    await accepted
    await expect(page.getByText('アカウントを削除しました')).toBeVisible()
    await expect(page.getByRole('link', { name: 'ログイン' })).toBeVisible()
    await submitLogin(page, accounts.eve.email, accounts.eve.password)
    await expect(page.getByText('メールアドレスかパスワードが違う')).toBeVisible()
  })

  test('A-10 ログインが必要な画面は、未ログインならログイン画面へ送られる', async ({ browser }) => {
    const { page } = await openPage(browser)
    for (const path of ['/boards', '/boards/new', '/items/new', '/advent_calendar_items/new']) {
      await page.goto(path)
      await expect(page).toHaveURL(/\/users\/sign_in$/)
      await expect(page.getByText('ログインもしくはアカウント登録してください。')).toBeVisible()
    }
  })
})
