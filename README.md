# radvent

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![build](https://github.com/haru/radvent/actions/workflows/build.yml/badge.svg)](https://github.com/haru/radvent/actions/workflows/build.yml)
[![Maintainability](https://qlty.sh/gh/haru/projects/radvent/maintainability.svg)](https://qlty.sh/gh/haru/projects/radvent)
[![codecov](https://codecov.io/gh/haru/radvent/branch/main/graph/badge.svg?token=MM74F6ZLL6)](https://codecov.io/gh/haru/radvent)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/haru/redmine_ai_helper)


Qiita風のアドベントカレンダー Webアプリです。Markdown で記事を執筆し、指定日を過ぎると自動的に公開されます。

[nanonanomachine/radvent](https://github.com/nanonanomachine/radvent) を元に以下の機能を追加・改造しています。

- ユーザー認証（Devise）
- 複数のアドベントカレンダーイベント対応
- いいね・コメント機能
- ファイル添付（CarrierWave）

Markdown パーサーに [marked](https://github.com/markedjs/marked)、シンタックスハイライトに [highlight.js](https://github.com/highlightjs/highlight.js) を使用しています。

---

## 目次

- [技術スタック](#技術スタック)
- [開発環境のセットアップ](#開発環境のセットアップ)
- [アプリの起動](#アプリの起動)
- [テスト](#テスト)
- [本番環境へのデプロイ](#本番環境へのデプロイ)
- [Docker](#docker)
- [アーキテクチャ](#アーキテクチャ)
- [環境変数一覧](#環境変数一覧)
- [ライセンス](#ライセンス)

---

## 技術スタック

| 種別 | 技術 |
|------|------|
| 言語 | Ruby >= 3.2 |
| フレームワーク | Ruby on Rails 8.1 |
| フロントエンド | esbuild / SCSS (Bootstrap 5 / mdb-ui-kit) |
| テンプレート | HAML |
| 認証 | Devise |
| DB（開発） | SQLite3 |
| DB（本番） | SQLite3 / MySQL 5.7+ / PostgreSQL |
| テスト | RSpec / FactoryBot / SimpleCov |
| CI | GitHub Actions |

---

## 開発環境のセットアップ

### 前提条件

- Ruby >= 3.0
- Node.js / Yarn
- SQLite3（デフォルト）

### 手順

```bash
# 1. 依存ライブラリのインストール
bundle install
yarn install

# 2. デフォルト設定ファイルを生成
#    config/database.yml / config/secrets.yml / config/initializers/devise.rb が作成される
bundle exec rake radvent:generate_default_settings

# 3. データベース作成 & マイグレーション
bundle exec rake db:create db:migrate

# 4. （任意）サンプルデータの投入
bundle exec rake db:seed
```

### 初期管理者ユーザー

マイグレーション後、以下の管理者アカウントが利用できます。**ログイン後、必ずパスワードを変更してください。**

| 項目 | 値 |
|------|----|
| メールアドレス | admin@example.com |
| パスワード | adminadmin |

---

## アプリの起動

```bash
bundle exec rails s
```

`http://localhost:3000` でアクセスできます。

日本語と英語のロケールに対応しており、ブラウザの言語設定に応じて自動切り替えされます。

---

## テスト

テストフレームワークには **RSpec** を使用しています。

### 全テストの実行

```bash
bundle exec rspec spec
```

### ディレクトリ・ファイル指定

```bash
# モデルスペックのみ
bundle exec rspec spec/models

# コントローラースペックのみ
bundle exec rspec spec/controllers

# 特定ファイルのみ
bundle exec rspec spec/models/user_spec.rb

# ファイルの特定行のみ
bundle exec rspec spec/models/user_spec.rb:42
```

### カバレッジレポート

テスト実行後、`coverage/index.html` にカバレッジレポートが生成されます（SimpleCov / LCOV 形式）。

```bash
bundle exec rspec spec
open coverage/index.html
```

### テスト構成

| ディレクトリ | 内容 |
|---|---|
| `spec/models/` | モデルスペック |
| `spec/controllers/` | コントローラースペック |
| `spec/factories/` | FactoryBot ファクトリ定義 |
| `spec/helpers/` | ヘルパースペック |

---

## 本番環境へのデプロイ

```bash
# 1. 設定ファイル生成
bundle exec rake radvent:generate_default_settings

# 2. アセットのプリコンパイル
bundle exec rake assets:precompile RAILS_ENV=production

# 3. DBマイグレーション
bundle exec rake db:migrate RAILS_ENV=production

# 4. シークレットキーを設定して起動
export SECRET_KEY_BASE=$(bundle exec rails secret)
bundle exec rails s -e production
```

---

## Docker

### docker run での起動

```bash
docker run -d -p 3000:3000 -v /host/data/directory:/var/radvent_data haru/radvent
```

### docker-compose の例（MySQL）

```yaml
services:
  radvent:
    image: haru/radvent:latest
    ports:
      - "3000:3000"
    restart: unless-stopped
    volumes:
      - "./docker/data:/var/radvent_data"
      - "./log:/usr/local/radvent/log"
    links:
      - mysql
    environment:
      DB: mysql
      DB_USERNAME: root
      DB_PASSWORD: example
      DB_HOST: mysql
      DB_CREATE_ON_START: "true"
  mysql:
    image: mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: example
    volumes:
      - "./docker/mysql:/var/lib/mysql"
```

### docker-compose の例（PostgreSQL）

```yaml
services:
  radvent:
    image: haru/radvent:latest
    ports:
      - "3000:3000"
    volumes:
      - "./docker/data:/var/radvent_data"
      - "./log:/usr/local/radvent/log"
    restart: unless-stopped
    environment:
      DB: postgres
      DB_USERNAME: postgres
      DB_PASSWORD: example
      DB_HOST: postgres
      DB_CREATE_ON_START: "true"
  postgres:
    image: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: example
    volumes:
      - "./docker/postgres:/var/lib/postgresql"
```

### 環境変数一覧

| キー | 値 | デフォルト |
|------|----|------------|
| `DB` | `sqlite3` / `mysql` / `postgres` | `sqlite3` |
| `DB_NAME` | データベース名 | `radvent` |
| `DB_USERNAME` | DBユーザー名 | — |
| `DB_PASSWORD` | DBパスワード | — |
| `DB_HOST` | DBホスト名 | — |
| `DB_PORT` | DBポート番号 | MySQL: `3306` / PostgreSQL: `5432` |
| `DB_CREATE_ON_START` | `true` にすると起動時に `db:create` を実行 | `false` |
| `RADVENT_TITLE` | ヘッダーに表示するサイト名 | `Advent Calendar` |

---

## アーキテクチャ

### モデル関連図

```
Event ──< AdventCalendarItem >── User
               │
               └── Item ──< Comment
                      └──< Like >── User
```

| モデル | 概要 |
|--------|------|
| `User` | Devise認証ユーザー。管理者フラグあり |
| `Event` | アドベントカレンダーイベント |
| `AdventCalendarItem` | イベントの日付枠（date は Integer 1〜31） |
| `Item` | Markdown 記事。`AdventCalendarItem` に 1対1 で紐付く |
| `Like` | 記事へのいいね |
| `Comment` | 記事へのコメント（`user_name` 文字列のみ保持） |
| `Attachment` | CarrierWave によるファイル添付 |

### ルーティングの注意点

- Event の詳細ページは ID ではなく名前ベースのルート（`/events/:name`）
- `show_event_path(event.name)` を使用すること（`event_path(event)` は誤り）

---

## ライセンス

[MIT](LICENSE)

---

## クレジット

- Original radvent: [Yohei Koyama](https://github.com/nanonanomachine)
