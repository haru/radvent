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

  test('C-2 (不正なID) 記号を含むIDでは、500にならず入力エラーが出る', async ({ browser }) => {
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
    await expect(page.getByLabel('ボードID')).toHaveValue('bad id!')
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
    const bobRow = page.getByRole('row', { name: accounts.bob.name })
    await expect(bobRow.locator('svg[data-icon="user"]')).toBeVisible()
    await expect(bobRow.locator('svg[data-icon="envelope"]')).toBeVisible()
    await expect(bobRow.getByRole('button', { name: '削除' }).locator('svg[data-icon="trash"]')).toBeVisible()

    await add(boards.private.boardId, accounts.bob.name)
    await expect(page.getByText('メンバーを追加しました')).toBeVisible()

    await add(boards.private.boardId, 'nobody-with-this-name')
    await expect(page.getByText('ユーザーが見つかりません')).toBeVisible()

    await add(boards.private.boardId, accounts.bob.email)
    await expect(page.getByText('すでにメンバーです')).toBeVisible()

    await add(boards.public.boardId, accounts.carol.name)
    await page.getByRole('link', { name: 'ボード設定に戻る' }).click()
    await expect(page).toHaveURL(new RegExp(`/boards/${boards.public.boardId}/edit$`))
    await page.goBack()
    await expect(page.getByRole('cell', { name: accounts.carol.name, exact: true })).toBeVisible()
    const dialogMessage = page.waitForEvent('dialog').then(async (dialog) => {
      await dialog.accept()
      return dialog.message()
    })
    await page.getByRole('row', { name: accounts.carol.name }).getByRole('button', { name: '削除' }).click()
    expect(await dialogMessage).toContain(accounts.carol.name)
    await expect(page.getByText('メンバーを削除しました')).toBeVisible()
    await expect(page.getByRole('cell', { name: accounts.carol.name, exact: true })).toHaveCount(0)
    await expect(page.getByText('メンバーがいません')).toBeVisible()
  })

  test('C-4b メンバー検索: 入力途中の候補を選んで追加でき、既存メンバーやオーナーは候補に出ない', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    await createBoard(page, { boardId: 'e2e-member-search', name: 'E2E メンバー検索ボード' })
    await page.goto('/boards/e2e-member-search/board_memberships')

    const input = page.getByPlaceholder('ユーザー名またはメールアドレス')
    const candidate = (account) => page.locator('#member-search-results').getByRole('option').filter({ hasText: account.email })
    const memberCell = (account) => page.getByRole('cell', { name: account.name, exact: true })
    const noMatch = page.getByText('該当するユーザーがいません')
    const add = () => page.getByRole('button', { name: 'メンバーを追加' }).click()

    await test.step('1文字では候補が出ず、2文字で名前とメールアドレスが見える', async () => {
      await input.fill('ca')
      await expect(candidate(accounts.carol)).toContainText(accounts.carol.name)
      await input.fill('e')
      await expect(page.getByRole('listbox')).toBeHidden()
    })

    await test.step('マウスで選ぶと入力欄に反映されるだけで、追加ボタンで確定する', async () => {
      await input.fill('e2e-ca')
      await candidate(accounts.carol).click()
      await expect(input).toHaveValue(new RegExp(accounts.carol.name))
      await expect(memberCell(accounts.carol)).toHaveCount(0)
      await add()
      await expect(page.getByText('メンバーを追加しました')).toBeVisible()
      await expect(memberCell(accounts.carol)).toBeVisible()
    })

    await test.step('メールアドレスの一部は大文字小文字を区別せず検索できる', async () => {
      await input.fill('BOB@E2E')
      await candidate(accounts.bob).click()
      await add()
      await expect(memberCell(accounts.bob)).toBeVisible()
    })

    await test.step('キーボードだけで候補を選んで追加できる', async () => {
      await input.fill('e2e-da')
      await expect(candidate(accounts.dave)).toBeVisible()
      await input.press('ArrowDown')
      await input.press('Enter')
      await expect(input).toHaveValue(new RegExp(accounts.dave.name))
      await expect(memberCell(accounts.dave)).toHaveCount(0)
      await input.press('Enter')
      await expect(memberCell(accounts.dave)).toBeVisible()
    })

    await test.step('選んだ後に入力欄を編集すると選択は解除され、入力値で処理される', async () => {
      await input.fill('admin@')
      await candidate(accounts.admin).click()
      await input.fill('nobody-with-this-name')
      await add()
      await expect(page.getByText('ユーザーが見つかりません')).toBeVisible()
      await expect(memberCell(accounts.admin)).toHaveCount(0)
    })

    await test.step('既存メンバー・オーナー・該当なしでは候補が出ない', async () => {
      for (const query of [accounts.carol.name, accounts.alice.name, 'zzzz-no-such-user']) {
        await input.fill(query)
        await expect(noMatch).toBeVisible()
        await expect(page.locator('#member-search-results [role="option"]')).toHaveCount(0)
        await input.fill('')
        await expect(noMatch).toBeHidden()
      }
    })
  })

  test('C-4c メンバー検索の操作: 間引き・取り消し・キーボード・IME・失敗表示', async ({ browser }) => {
    const { page, context } = await openAs(browser, accounts.alice)
    await createBoard(page, { boardId: 'e2e-member-search-ui', name: 'E2E メンバー検索操作ボード' })
    const searchUrl = '**/board_memberships/search**'
    const searches = []
    const logged = []
    page.on('request', (request) => { if (request.url().includes('/board_memberships/search')) searches.push(request.url()) })
    page.on('console', (message) => { if (message.text().startsWith('Member search')) logged.push(message.text()) })
    const open = async () => {
      await page.goto('/boards/e2e-member-search-ui/board_memberships')
      return page.getByPlaceholder('ユーザー名またはメールアドレス')
    }
    const input = await open()
    const listbox = page.getByRole('listbox')
    const options = page.locator('#member-search-results [role="option"]')
    const userId = page.locator('input[name="user_id"]')
    const candidate = (account) => options.filter({ hasText: account.email })
    const alert = page.getByRole('alert')

    await test.step('入力欄は長さに上限がある', async () => {
      await expect(input).toHaveAttribute('maxlength', '255')
    })

    await test.step('連続入力は1回の検索にまとまり、1文字では検索しない', async () => {
      searches.length = 0
      await input.pressSequentially('e2e-ca', { delay: 30 })
      await expect(candidate(accounts.carol)).toBeVisible()
      expect(searches).toHaveLength(1)
      searches.length = 0
      await input.fill('e')
      await page.waitForTimeout(600)
      expect(searches).toHaveLength(0)
    })

    await test.step('↑は最後の候補から、↓は先頭へ回り込み、選択中の候補が支援技術に伝わる', async () => {
      await input.fill('e2e-')
      await expect(options.nth(1)).toBeVisible()
      const count = await options.count()
      await input.press('ArrowUp')
      await expect(options.nth(count - 1)).toHaveAttribute('aria-selected', 'true')
      await expect(input).toHaveAttribute('aria-activedescendant', await options.nth(count - 1).getAttribute('id'))
      await input.press('ArrowDown')
      await expect(options.nth(0)).toHaveAttribute('aria-selected', 'true')
      await expect(options.nth(count - 1)).toHaveAttribute('aria-selected', 'false')
    })

    await test.step('候補を選んだ直後に入力すると古い候補は確定されない', async () => {
      await input.press('ArrowDown')
      await input.press('x')
      await input.press('Enter')
      await expect(userId).toHaveValue('')
      await expect(input).toHaveValue(/x$/)
    })

    await test.step('Esc とフォーカス移動で候補が閉じ、検索待ちの結果が後から開き直さない', async () => {
      await input.fill('e2e-ca')
      await expect(listbox).toBeVisible()
      await input.press('Escape')
      await expect(listbox).toBeHidden()

      await page.route(searchUrl, async (route) => {
        const response = await route.fetch()
        await new Promise((resolve) => setTimeout(resolve, 800))
        await route.fulfill({ response }).catch(() => {}) // the page has cancelled the request
      })
      await input.fill('e2e-da')
      await page.waitForTimeout(400)
      await input.press('Escape')
      await page.waitForTimeout(1200)
      await expect(listbox).toBeHidden()

      await page.unroute(searchUrl)
      await input.fill('e2e-ca')
      await expect(listbox).toBeVisible()
      await input.blur()
      await expect(listbox).toBeHidden()
    })

    await test.step('古い検索の応答は新しい検索の結果を上書きしない', async () => {
      let first = true
      await page.route(searchUrl, async (route) => {
        const slow = first
        first = false
        const response = await route.fetch()
        if (slow) await new Promise((resolve) => setTimeout(resolve, 1200))
        await route.fulfill({ response }).catch(() => {})
      })
      await input.fill('e2e-ca')
      await page.waitForRequest((request) => request.url().includes('member_query=e2e-ca'))
      await input.fill('e2e-da')
      await expect(candidate(accounts.dave)).toBeVisible()
      await page.waitForTimeout(1500)
      await expect(candidate(accounts.dave)).toBeVisible()
      await expect(candidate(accounts.carol)).toHaveCount(0)
      await page.unroute(searchUrl)
    })

    await test.step('IMEの変換中は検索せず、確定で1回だけ検索し、変換を確定するEnterで候補を選ばない', async () => {
      await input.fill('')
      searches.length = 0
      await input.evaluate((element) => {
        element.dispatchEvent(new CompositionEvent('compositionstart', { bubbles: true }))
        element.value = 'e2e-ca'
        element.dispatchEvent(new InputEvent('input', { bubbles: true, isComposing: true }))
      })
      await page.waitForTimeout(600)
      expect(searches).toHaveLength(0)
      await input.evaluate((element) => element.dispatchEvent(new CompositionEvent('compositionend', { bubbles: true })))
      await expect(candidate(accounts.carol)).toBeVisible()
      expect(searches).toHaveLength(1)
      await input.press('ArrowDown')
      await input.evaluate((element) => element.dispatchEvent(
        new KeyboardEvent('keydown', { key: 'Enter', isComposing: true, bubbles: true, cancelable: true })
      ))
      await expect(userId).toHaveValue('')
      await expect(listbox).toBeVisible()
    })

    await test.step('ページを戻って復元されても候補は開いておらず、キーボード操作で例外にならない', async () => {
      await input.fill('e2e-ca')
      await expect(listbox).toBeVisible()
      await page.goto('/boards')
      await page.goBack()
      const restored = page.getByPlaceholder('ユーザー名またはメールアドレス')
      await expect(page.getByRole('listbox')).toBeHidden()
      await restored.fill('e2e-ca')
      await expect(candidate(accounts.carol)).toBeVisible()
      await restored.press('ArrowDown')
      await expect(options.first()).toHaveAttribute('aria-selected', 'true')
    })

    await test.step('失敗は原因ごとに表示され、「該当なし」とは区別され、次の入力で消える', async () => {
      const failures = [
        [429, '検索の回数が上限に達しました'],
        [500, '検索に失敗しました'],
        [403, '権限がありません'],
        [404, '権限がありません']
      ]
      for (const [status, text] of failures) {
        await page.route(searchUrl, (route) => route.fulfill({ status, contentType: 'text/plain', body: 'x' }))
        await input.fill('e2e-ca')
        await expect(alert).toContainText(text)
        await expect(page.getByText('該当するユーザーがいません')).toBeHidden()
        await page.unroute(searchUrl)
      }

      await page.route(searchUrl, (route) => route.fulfill({ status: 200, contentType: 'text/plain', body: 'x' }))
      await input.fill('e2e-ca')
      await expect(alert).toContainText('検索に失敗しました')
      await page.unroute(searchUrl)

      await page.route(searchUrl, (route) => route.abort())
      await input.fill('e2e-ca')
      await expect(alert).toContainText('検索に失敗しました')
      await page.unroute(searchUrl)

      await input.fill('e2e-ca')
      await expect(alert).toBeHidden()
      await expect(candidate(accounts.carol)).toBeVisible()
      expect(logged.length).toBeGreaterThanOrEqual(6)
      // The application logs each failure to the console on purpose; they are not unexpected errors.
      clearJsErrors()
    })

    await test.step('セッション切れはログインし直しを促す', async () => {
      await context.clearCookies()
      await input.fill('e2e-da')
      await expect(alert).toContainText('ログインの有効期限が切れました')
      clearJsErrors()
    })
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
    await expect(alice.page.getByText('自分用のイベント')).toBeVisible()
    const settings = alice.page.getByRole('row', { name: boards.public.name }).getByRole('link', { name: '設定', exact: true })
    await expect(settings.locator('svg[data-icon="gear"]')).toBeVisible()
    await expect(alice.page.getByRole('link', { name: 'ボード設定' })).toHaveCount(0)
    const carol = await openAs(browser, accounts.carol)
    await carol.page.goto('/boards')
    await expect(carol.page.getByText('ボードがまだありません')).toBeVisible()
    await expect(carol.page.getByText('自分用のイベント')).toBeVisible()
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
