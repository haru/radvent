---
name: playwright-screen-access
description: Playwright MCP を使ってアプリ画面にアクセスし、操作・検証するスキル。browserless 経由でのアクセス方法、ログイン手順、スクリーンショット取得などを含む。
version: 1.0.0
source: local-session-analysis
---

# Playwright でアプリ画面にアクセスする

## 前提条件

- アプリサーバーはすでに起動中であること
- Playwright MCP が有効であること（browserless コンテナ経由）

## アクセス URL

browserless コンテナからはアプリが `app` というホスト名で見える。

```
http://app:3000
```

> ローカルマシンから直接アクセスする場合は `http://localhost:3000`

## 基本手順

### Step 1: ツールスキーマをロードする

Playwright MCP ツールは遅延ロードのため、使用前に `ToolSearch` でスキーマを取得する。

```
ToolSearch: select:mcp__playwright__browser_navigate,mcp__playwright__browser_take_screenshot,mcp__playwright__browser_snapshot
```

必要に応じて追加ツールもロード:

```
ToolSearch: select:mcp__playwright__browser_click,mcp__playwright__browser_fill_form,mcp__playwright__browser_type
```

### Step 2: ページに移動する

```json
mcp__playwright__browser_navigate: { "url": "http://app:3000" }
```

### Step 3: スクリーンショットを撮る

```json
mcp__playwright__browser_take_screenshot: { "type": "png" }
```

アクセシビリティスナップショット（要素操作に使う）:

```json
mcp__playwright__browser_snapshot: {}
```

## ログイン手順

管理者アカウント:
- Email: `admin@example.com`
- Password: `adminadmin`

```
1. mcp__playwright__browser_navigate → http://app:3000/users/sign_in
2. mcp__playwright__browser_fill_form → email + password フィールドを入力
3. mcp__playwright__browser_click → [type=submit] ボタンをクリック
4. ログイン成功 → http://app:3000/ にリダイレクトされる
```

### fill_form の例

```json
mcp__playwright__browser_fill_form: {
  "fields": [
    { "target": "#user_email", "name": "メールアドレス", "type": "textbox", "value": "admin@example.com" },
    { "target": "#user_password", "name": "パスワード", "type": "textbox", "value": "adminadmin" }
  ]
}
```

## よく使う操作

### クリック

```json
mcp__playwright__browser_click: {
  "target": "button.btn-primary",
  "element": "送信ボタン"
}
```

### テキスト入力

```json
mcp__playwright__browser_type: {
  "target": "#search_input",
  "text": "検索キーワード",
  "submit": true
}
```

### ナビゲーション

```json
mcp__playwright__browser_navigate: { "url": "http://app:3000/items/new" }
```

## 確認パターン

画面の変更が反映されているか確認するには:

1. `mcp__playwright__browser_navigate` でページを開く
2. `mcp__playwright__browser_take_screenshot` でスクリーンショットを取得して目視確認
3. `mcp__playwright__browser_snapshot` でアクセシビリティツリーを取得してDOM構造を確認

## 注意事項

- `browser_snapshot` は要素操作のために使う（クリックやフォーム入力のターゲット取得）
- `browser_take_screenshot` は視覚的な確認のために使う
- ToolSearch で取得したスキーマは会話中はキャッシュされるため、再取得不要
- browserless 経由のため、ブラウザは外部コンテナで動作している
