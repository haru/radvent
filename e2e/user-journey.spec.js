import { test, expect } from '@playwright/test'
import {
  accounts, closeOpenedContexts, login, logout, openAs, openPage, rememberLogin, submitLogin
} from './support/accounts.js'
import { acceptNextDialog } from './support/dialog.js'
import { fillMarkdown, openPreview } from './support/editor.js'
import { createEvent, dayCell, joinDay, signUp, writeArticle } from './support/forms.js'
import { futureEventPeriod, pastEventPeriod } from './support/dates.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

const boardId = 'e2e-board'
const boardName = 'E2E ボード'
const boardNameEdited = 'E2E ボード(編集後)'
const pastEvent = { name: 'e2e-past', title: 'E2E 過去のカレンダー', ...pastEventPeriod() }
const futureEvent = { name: 'e2e-future', title: 'E2E 未来のカレンダー', ...futureEventPeriod() }
const pastEventPath = `/boards/${boardId}/events/${pastEvent.name}`
const futureEventPath = `/boards/${boardId}/events/${futureEvent.name}`

const articleBody = '# E2E 見出し\n\nE2E 本文の **強調** です。'
const articleBodyEdited = '# E2E 編集後見出し\n\nE2E 編集後の本文です。'
const articleTitle = 'E2E 記事'
const articleTitleEdited = 'E2E 記事(編集後)'

test.describe.serial('利用者の一連の操作', () => {
  // Path of the published article (set by US4, used by US5).
  let itemPath

  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  // Uncaught browser errors fail the test even when every assertion passed.
  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('US2 初回ログインからユーザー作成まで', async ({ page, browser }) => {
    await test.step('AS 2-1 初期管理者でログインし、ユーザー一覧を開ける', async () => {
      await login(page, accounts.admin)
      await page.goto('/users')
      await expect(page.getByRole('cell', { name: accounts.admin.email })).toBeVisible()
    })

    // Each user registers in a context of their own, which is never logged out, so the saved login
    // state stays valid even if sessions are revoked on logout one day.
    await test.step('AS 2-2 新規登録すると、そのユーザーでログインした状態になる', async () => {
      for (const account of [accounts.alice, accounts.bob]) {
        const { page: registrationPage } = await openPage(browser)
        await signUp(registrationPage, account)
        await rememberLogin(registrationPage, account)
      }
    })

    await test.step('AS 2-3 ログアウトして、同じ認証情報で再びログインできる', async () => {
      await logout(page)
      await login(page, accounts.alice)
      await logout(page)
      await login(page, accounts.alice)
    })

    await test.step('AS 2-4 誤ったパスワードではログインできない', async () => {
      await logout(page)
      await submitLogin(page, accounts.alice.email, 'wrong-password')
      await expect(page.getByText('メールアドレスかパスワードが違うか、一時的にログインが制限されています。')).toBeVisible()
      await expect(page).toHaveURL(/\/users\/sign_in$/)
    })

    await test.step('AS 2-5 管理者のユーザー一覧に、登録したユーザーが出る', async () => {
      await login(page, accounts.admin)
      await page.goto('/users')
      await expect(page.getByRole('cell', { name: accounts.alice.email })).toBeVisible()
      await expect(page.getByRole('cell', { name: accounts.bob.email })).toBeVisible()
    })
  })

  test('US3 ボードとイベントの作成', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)

    await test.step('AS 3-1 ボードを作ると、ボードの画面と一覧に出る', async () => {
      await page.goto('/boards')
      await page.getByRole('link', { name: '新しいボードを作成' }).click()
      await page.getByLabel('ボードID').fill(boardId)
      await page.getByLabel('ボード名').fill(boardName)
      await page.getByRole('radio', { name: /^公開 —/ }).check()
      await page.getByRole('button', { name: '登録する' }).click()
      await expect(page.getByRole('heading', { name: boardName })).toBeVisible()
      await page.goto('/boards')
      await expect(page.getByRole('cell', { name: boardName, exact: true })).toBeVisible()
    })

    await test.step('AS 3-2 ボードを編集すると、変更が反映される', async () => {
      await page.getByRole('row', { name: boardName }).getByRole('link', { name: 'ボード設定' }).click()
      await page.getByLabel('ボード名').fill(boardNameEdited)
      await page.getByRole('button', { name: '更新する' }).click()
      await expect(page.getByRole('heading', { name: boardNameEdited })).toBeVisible()
    })

    await test.step('AS 3-3 イベントを作ると、ボードに出て、期間分のカレンダーが出る', async () => {
      await page.goto(`/boards/${boardId}`)
      await createEvent(page, pastEvent)
      await createEvent(page, futureEvent)
      await expect(page.getByRole('heading', { name: pastEvent.title })).toBeVisible()
      await page.goto(pastEventPath)
      await expect(page.getByRole('link', { name: '参加登録' })).toHaveCount(pastEvent.lastDay)
    })

    await test.step('AS 3-4 イベントを編集すると、変更が反映される', async () => {
      await page.goto(`${pastEventPath}/edit`)
      await page.getByLabel('説明').fill('E2E 編集後の説明')
      await page.getByRole('button', { name: '更新する' }).click()
      await expect(page.getByText('E2E 編集後の説明')).toBeVisible()
    })

    await test.step('AS 3-5 ボードにメンバーを追加すると、メンバー一覧に出る', async () => {
      await page.goto(`/boards/${boardId}/edit`)
      await page.getByRole('link', { name: 'メンバー管理' }).click()
      await page.getByPlaceholder('ユーザー名またはメールアドレス').fill(accounts.bob.name)
      await page.getByRole('button', { name: 'メンバーを追加' }).click()
      await expect(page.getByRole('cell', { name: accounts.bob.name, exact: true })).toBeVisible()
    })
  })

  test('US4 記事の登録・編集・削除', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.alice)
    let deletableSlotPath
    let deletableItemPath

    await test.step('AS 4-1 空いている日に参加登録すると、枠に名前が出る', async () => {
      await joinDay(page, pastEventPath, 1)
      await joinDay(page, pastEventPath, 2)
      await page.goto(pastEventPath)
      await expect(dayCell(page, 1)).toContainText(accounts.alice.name)
      await expect(dayCell(page, 2)).toContainText(accounts.alice.name)
    })

    // AS 4-3 runs before AS 4-2 because it previews the form that has not been saved yet.
    await test.step('AS 4-3 保存する前に、プレビューで整形された本文を確認できる', async () => {
      await dayCell(page, 1).getByRole('link', { name: '編集' }).click()
      await page.getByRole('link', { name: '記事を登録する' }).click()
      await page.getByLabel('タイトル').fill(articleTitle)
      await fillMarkdown(page, articleBody)
      const preview = await openPreview(page)
      await expect(preview.locator('#item-show h1')).toHaveText('E2E 見出し')
      await expect(preview.locator('#item-show strong')).toHaveText('強調')
      await preview.close()
    })

    await test.step('AS 4-2 記事を保存すると、整形された内容が記事の画面に出る', async () => {
      await page.getByRole('button', { name: '登録する' }).click()
      await expect(page.getByText('記事が登録されています')).toBeVisible()
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      await expect(page).toHaveURL(/\/items\/\d+$/)
      itemPath = new URL(page.url()).pathname
      await expect(page.locator('.item-show-header-title')).toHaveText(articleTitle)
      await expect(page.locator('#item-show h1')).toHaveText('E2E 見出し')
      await expect(page.locator('#item-show strong')).toHaveText('強調')
    })

    await test.step('AS 4-4 記事を編集すると、変更後の内容が出る', async () => {
      await page.getByRole('link', { name: '記事を編集する' }).click()
      await page.getByLabel('タイトル').fill(articleTitleEdited)
      await fillMarkdown(page, articleBodyEdited, { replace: true })
      await page.getByRole('button', { name: '登録する' }).click()
      await expect(page.getByText('記事が登録されています')).toBeVisible()
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      await expect(page.locator('.item-show-header-title')).toHaveText(articleTitleEdited)
      await expect(page.locator('#item-show h1')).toHaveText('E2E 編集後見出し')
    })

    // An article has no required field, so the input errors are provoked on an event instead.
    await test.step('AS 4-6 必須項目を空にすると、保存されずに入力エラーが出る', async () => {
      await page.goto(`${pastEventPath}/edit`)
      const title = page.getByLabel('タイトル')
      // The required field stops an empty submit in the browser, so nothing reaches the server.
      await title.fill('')
      await page.getByRole('button', { name: '更新する' }).click()
      await expect(page).toHaveURL(/\/edit$/)
      expect(await title.evaluate((input) => input.validationMessage)).not.toBe('')
      // A title already used in the board is rejected by the server, which shows the error list.
      await title.fill(futureEvent.title)
      await page.getByRole('button', { name: '更新する' }).click()
      await expect(page.locator('.alert-danger')).toBeVisible()
      await page.goto(pastEventPath)
      await expect(page.getByRole('heading', { name: pastEvent.title })).toBeVisible()
    })

    // The slot and article that AS 4-5 deletes. An empty article title is accepted and shown as 無題.
    await test.step('AS 4-6 (補足) 記事のタイトルは必須ではなく、空なら無題と表示される', async () => {
      await page.goto(pastEventPath)
      await dayCell(page, 2).getByRole('link', { name: '編集' }).click()
      await writeArticle(page, 'E2E 削除する記事', 'E2E 削除される本文')
      deletableSlotPath = new URL(page.url()).pathname
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      deletableItemPath = new URL(page.url()).pathname
      await page.getByRole('link', { name: '記事を編集する' }).click()
      await page.getByLabel('タイトル').fill('')
      await page.getByRole('button', { name: '登録する' }).click()
      await expect(page.getByText('記事が登録されています')).toBeVisible()
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      await expect(page.locator('.item-show-header-title')).toHaveText('無題')
    })

    await test.step('AS 4-5 枠を削除すると、記事が消えて、その日は再び空きになる', async () => {
      await page.goto(deletableSlotPath)
      const confirmed = acceptNextDialog(page)
      await page.getByRole('button', { name: '削除' }).click()
      await confirmed
      await expect(page).toHaveURL(new RegExp(`${pastEventPath}$`))
      await expect(dayCell(page, 2).getByRole('link', { name: '参加登録' })).toBeVisible()
      await expect(dayCell(page, 2)).not.toContainText(accounts.alice.name)
      const response = await page.goto(deletableItemPath)
      expect(response.status()).toBe(404)
      await expect(page.getByText('E2E 削除される本文')).toHaveCount(0)
    })

    await test.step('AS 4-7 十分先の日付の記事は、作者以外には見えない', async () => {
      await joinDay(page, futureEventPath, 1)
      await writeArticle(page, 'E2E 未来の記事', 'E2E 未来の本文')
      // The "show" link would be redirected for a future article, so derive the path from the edit link.
      const editHref = await page.getByRole('link', { name: '投稿記事を編集する' }).getAttribute('href')
      expect(editHref).toMatch(/\/items\/\d+\/edit$/)
      const futureItemPath = new URL(editHref, page.url()).pathname.replace(/\/edit$/, '')

      const bob = await openAs(browser, accounts.bob)
      const visitor = await openPage(browser)
      for (const viewer of [page, bob.page, visitor.page]) {
        await viewer.goto(futureItemPath)
        await expect(viewer).toHaveURL((url) => url.pathname === '/')
        await expect(viewer.getByText('E2E 未来の記事')).toHaveCount(0)
        await expect(viewer.getByText('E2E 未来の本文')).toHaveCount(0)
      }

      await page.goto(`${futureItemPath}/edit`)
      await expect(page.locator('.CodeMirror')).toContainText('E2E 未来の本文')
      const preview = await openPreview(page)
      await expect(preview.locator('#item-show')).toContainText('E2E 未来の本文')
      await preview.close()
    })
  })

  test('US5 コメントといいね', async ({ browser }) => {
    const likeButton = (page) => page.locator('#like-button')
    // Font Awesome swaps <i> for an <svg>; the prefix tells solid (liked) from regular (not liked).
    const heart = (page) => page.locator('#like-button svg')

    await test.step('AS 5-1 コメントを投稿すると、ページを読み直さずに出る', async () => {
      const { page } = await openPage(browser)
      await page.goto(itemPath)
      await page.evaluate(() => { window.__e2eMarker = true })
      await page.getByLabel('お名前を入力してください').fill('E2E 読者')
      await page.getByLabel('コメントを入力してください').fill('E2E コメント')
      await page.getByRole('button', { name: '投稿する' }).click()
      await expect(page.locator('#comments_list')).toContainText('E2E 読者')
      await expect(page.locator('#comments_list')).toContainText('E2E コメント')
      expect(await page.evaluate(() => window.__e2eMarker)).toBe(true)
    })

    await test.step('AS 5-2 削除権限を持つユーザーがコメントを削除すると、消える', async () => {
      const { page } = await openAs(browser, accounts.alice)
      await page.goto(itemPath)
      await expect(page.locator('#comments_list')).toContainText('E2E コメント')
      const confirmed = acceptNextDialog(page)
      await page.locator('#comments_list').getByRole('button', { name: '削除' }).click()
      await confirmed
      await expect(page.locator('#comments_list')).not.toContainText('E2E コメント')
    })

    const bob = await openAs(browser, accounts.bob)

    await test.step('AS 5-3 いいねを押すと、数が 1 増え、いいね済みになる', async () => {
      await bob.page.goto(itemPath)
      await expect(likeButton(bob.page)).toHaveText('0')
      await expect(heart(bob.page)).toHaveAttribute('data-prefix', 'far')
      await likeButton(bob.page).click()
      await expect(likeButton(bob.page)).toHaveText('1')
      await expect(heart(bob.page)).toHaveAttribute('data-prefix', 'fas')
    })

    await test.step('AS 5-4 もう一度押すと、数が 1 減り、元に戻る', async () => {
      await likeButton(bob.page).click()
      await expect(likeButton(bob.page)).toHaveText('0')
      await expect(heart(bob.page)).toHaveAttribute('data-prefix', 'far')
    })

    await test.step('AS 5-5 別々のユーザーがいいねすると、人数分になる', async () => {
      await likeButton(bob.page).click()
      await expect(likeButton(bob.page)).toHaveText('1')
      const alice = await openAs(browser, accounts.alice)
      await alice.page.goto(itemPath)
      await likeButton(alice.page).click()
      await expect(likeButton(alice.page)).toHaveText('2')
      await alice.page.goto(itemPath)
      await expect(likeButton(alice.page)).toHaveText('2')
    })
  })
})
