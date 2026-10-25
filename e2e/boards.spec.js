import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs, openPage } from './support/accounts.js'
import { acceptNextDialog } from './support/dialog.js'
import { createBoard } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

// alice owns every board of this file; bob becomes a member of the protected and private ones.
const boards = {
  public: { boardId: 'e2e-vis-public', name: 'E2E 公開ボード', visibility: '公開' },
  protected: { boardId: 'e2e-vis-protected', name: 'E2E 限定公開ボード', visibility: '限定公開' },
  private: { boardId: 'e2e-vis-private', name: 'E2E 非公開ボード', visibility: '非公開' }
}
const createEventLink = (page) => page.getByRole('link', { name: 'イベントを作成' })
const otherBoardLink = (page, name) => page.locator('#other-boards').getByRole('link', { name: new RegExp(name) })

test.describe.serial('ボード', () => {
  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('C-2 ボードの入力エラー: 空欄・不正なID・重複したIDでは作れない', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    const submit = async (boardId, name) => {
      await page.goto('/boards/new')
      await page.getByLabel('ボードID').fill(boardId)
      await page.getByLabel('ボード名').fill(name)
      await page.getByRole('button', { name: '登録する' }).click()
      await expect(page.locator('.alert-danger li').first()).toBeVisible()
      // Turbo keeps the address of the form when it renders the 422 answer.
      await expect(page).toHaveURL(/\/boards\/new$/)
    }
    await test.step('空欄', () => submit('', ''))
    await test.step('予約済みのID', () => submit('users', 'E2E 予約ID'))
    await test.step('すでに使われているID', () => submit('e2e-board', 'E2E 重複ID'))
    await page.goto('/boards')
    await expect(page.getByRole('cell', { name: 'E2E 重複ID' })).toHaveCount(0)
  })

  // BUG-2: an id with a character outside a-z, 0-9, "-" and "_" fails validation, but the layout then builds
  // board_path from the invalid id, so the request ends in ActionController::UrlGenerationError (500).
  // Remove test.fail() once fixed.
  test('C-2 (不正なID) 記号を含むIDでは、500にならず入力エラーが出る', async ({ browser }) => {
    test.fail()
    const { page } = await openAs(browser, accounts.alice)
    await page.goto('/boards/new')
    await page.getByLabel('ボードID').fill('Bad ID!')
    await page.getByLabel('ボード名').fill('E2E 不正ID')
    const [response] = await Promise.all([
      page.waitForResponse((r) => r.url().endsWith('/boards') && r.request().method() === 'POST'),
      page.getByRole('button', { name: '登録する' }).click()
    ])
    expect(response.status()).toBe(422)
    await expect(page.locator('.alert-danger li').first()).toBeVisible()
  })

  test('C-4 メンバー管理: メールアドレスでも名前でも追加でき、未登録・重複は弾かれ、削除できる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    for (const board of Object.values(boards)) {
      await createBoard(page, board)
    }
    const members = (id) => `/boards/${id}/board_memberships`
    const add = async (id, query) => {
      await page.goto(members(id))
      await page.getByPlaceholder('ユーザー名またはメールアドレス').fill(query)
      await page.getByRole('button', { name: 'メンバーを追加' }).click()
    }

    await add(boards.protected.boardId, accounts.bob.email)
    await expect(page.getByText('メンバーを追加しました')).toBeVisible()
    await expect(page.getByRole('cell', { name: accounts.bob.name, exact: true })).toBeVisible()

    await add(boards.private.boardId, accounts.bob.name)
    await expect(page.getByText('メンバーを追加しました')).toBeVisible()

    await add(boards.private.boardId, 'nobody-with-this-name')
    await expect(page.getByText('ユーザーが見つかりません')).toBeVisible()

    await add(boards.private.boardId, accounts.bob.email)
    await expect(page.getByText('すでにメンバーです')).toBeVisible()

    await add(boards.public.boardId, accounts.carol.name)
    await expect(page.getByRole('cell', { name: accounts.carol.name, exact: true })).toBeVisible()
    const confirmed = acceptNextDialog(page)
    await page.getByRole('row', { name: accounts.carol.name }).getByRole('button', { name: '削除' }).click()
    await confirmed
    await expect(page.getByText('メンバーを削除しました')).toBeVisible()
    await expect(page.getByRole('cell', { name: accounts.carol.name, exact: true })).toHaveCount(0)
    await expect(page.getByText('メンバーがいません')).toBeVisible()
  })

  test('C-3 公開範囲ごとに、オーナー・メンバー・他のユーザー・ゲストの見え方が決まる', async ({ browser }) => {
    const alice = await openAs(browser, accounts.alice)
    const bob = await openAs(browser, accounts.bob)
    const carol = await openAs(browser, accounts.carol)
    const guest = await openPage(browser)
    const view = async (page, board) => {
      const response = await page.goto(`/boards/${board.boardId}`)
      return response.status()
    }
    // [viewer, board, status, can create events]
    const expectations = [
      [alice, 'public', 200, true], [bob, 'public', 200, true], [carol, 'public', 200, true], [guest, 'public', 200, false],
      [alice, 'protected', 200, true], [bob, 'protected', 200, true], [carol, 'protected', 200, false],
      [guest, 'protected', 200, false],
      [alice, 'private', 200, true], [bob, 'private', 200, true], [carol, 'private', 404, null], [guest, 'private', 404, null]
    ]
    for (const [viewer, key, status, canCreate] of expectations) {
      const label = `${key} as ${viewer === alice ? 'alice' : viewer === bob ? 'bob' : viewer === carol ? 'carol' : 'guest'}`
      expect(await view(viewer.page, boards[key]), label).toBe(status)
      if (status === 200) {
        await expect(viewer.page.getByRole('heading', { name: boards[key].name }), label).toBeVisible()
        await expect(createEventLink(viewer.page), label).toHaveCount(canCreate ? 1 : 0)
      } else {
        await expect(viewer.page.getByText('404 Not Found'), label).toBeVisible()
      }
    }

    // The list of other boards on the TOP follows the same visibility.
    for (const [viewer, listed] of [[guest, ['public', 'protected']], [carol, ['public', 'protected']],
      [bob, ['public', 'protected', 'private']], [alice, ['public', 'protected', 'private']]]) {
      await viewer.page.goto('/')
      for (const key of Object.keys(boards)) {
        await expect(otherBoardLink(viewer.page, boards[key].name), key).toHaveCount(listed.includes(key) ? 1 : 0)
      }
    }
  })

  test('C-5 ボード一覧は自分のボードだけで、他人のボード設定や未ログインでは開けない', async ({ browser }) => {
    const alice = await openAs(browser, accounts.alice)
    await alice.page.goto('/boards')
    for (const board of Object.values(boards)) {
      await expect(alice.page.getByRole('cell', { name: board.name, exact: true })).toBeVisible()
    }
    const carol = await openAs(browser, accounts.carol)
    await carol.page.goto('/boards')
    await expect(carol.page.getByText('ボードがまだありません')).toBeVisible()
    await expect(carol.page.getByRole('cell', { name: boards.public.name, exact: true })).toHaveCount(0)

    for (const path of ['edit', 'board_memberships']) {
      const response = await carol.page.goto(`/boards/${boards.public.boardId}/${path}`)
      expect(response.status(), path).toBe(403)
    }
    const bob = await openAs(browser, accounts.bob)
    expect((await bob.page.goto(`/boards/${boards.private.boardId}/edit`)).status()).toBe(403)

    const guest = await openPage(browser)
    await guest.page.goto(`/boards/${boards.public.boardId}/edit`)
    await expect(guest.page).toHaveURL(/\/users\/sign_in$/)
  })

  test('C-7 ボードの削除: IDが一致するまで削除できず、削除するとボードは見つからなくなる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    const board = { boardId: 'e2e-to-delete', name: 'E2E 削除するボード' }
    await createBoard(page, board)
    await page.goto(`/boards/${board.boardId}/edit`)
    const deleteButton = page.getByRole('button', { name: 'ボードを削除' })
    await page.getByLabel('ボードID確認').fill('wrong-id')
    await expect(deleteButton).toBeDisabled()
    await page.getByLabel('ボードID確認').fill(board.boardId)
    await expect(deleteButton).toBeEnabled()
    const confirmed = acceptNextDialog(page)
    await deleteButton.click()
    await confirmed
    await expect(page.getByText('ボードを削除しました')).toBeVisible()
    await expect(page.getByRole('cell', { name: board.name, exact: true })).toHaveCount(0)
    const response = await page.goto(`/boards/${board.boardId}`)
    expect(response.status()).toBe(404)
  })

  test('C-8 存在しないボード・イベント・記事は 404 ページになる', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    for (const path of ['/boards/no-such-board', '/boards/no-such-board/events/x', `/boards/${boards.public.boardId}/events/x`,
      '/events/no-such-event', '/items/999999', '/advent_calendar_items/999999']) {
      const response = await page.goto(path)
      expect(response.status(), path).toBe(404)
      await expect(page.getByText('404 Not Found'), path).toBeVisible()
    }
  })
})
