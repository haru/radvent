radvent
=======

[![Build Status](https://travis-ci.org/haru/radvent.svg?branch=master)](https://travis-ci.org/haru/radvent)
[![Maintainability](https://api.codeclimate.com/v1/badges/6ef37e4698d17ed0596b/maintainability)](https://codeclimate.com/github/haru/radvent/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/6ef37e4698d17ed0596b/test_coverage)](https://codeclimate.com/github/haru/radvent/test_coverage)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)




QiitaライクなAdventCalendarアプリです。Markdownを用い記事を登録します。記事は事前に登録し、該当日がすぎると自動的に公開されます。

以下に公開されている radvent を元に改造を行いました。
https://github.com/nanonanomachine/radvent/

元のradventはシンプルで素晴らしいツールですが、こちらのバージョンではオリジナルに以下の改造を加えています。

- ユーザ認証
- 複数のAdvent Calendarイベント対応

radventはMarkdownパーサーとして[chjj/marked](https://github.com/chjj/marked)を、シンタックスハイライトに[isagalaev/highlight.js](https://github.com/isagalaev/highlight.js)を用いています。

## インストール

```$ bundle install```

以下のコマンドを実行し、デフォルトの設定ファイルを作ります。

```$ bundle exec rake radvent:generate_default_settings```

- config/database.yml
- config/secrets.yml
- config/initializers/devise.yml

が作られるので必要に応じて編集します。

```$ bundle exec rake db:migrate RAILS_ENV=production```

でDBをマイグレーション後、以下のコマンドでradventを起動します。


```bash
$ export SECRET_KEY_BASE=XXXXXXX(シークレットキー)
$ bundle exec rails s -e production
```

シークレットキーは
```bundle exec rake secret```
等で生成してください。

http://localhost:3000

### 初期ユーザー

以下の管理者ユーザーが登録されています。ログイン後、パスワードを変更してください。

- ログイン: admin@example.com
- パスワード: adminadmin

また日本語と英語のロケールがサポートされています。
ブラウザの言語設定によって切り替わります。

### メール認証設定

未稿

## Docker

### Start container with docker command

```
$ docker run -d -p 3000:3000 -v /tmp/data:/var/radvent_data haru/radvent
```

### docker-compose.yml sample

```yaml
version: '2'
services:
  radvent:
    image: haru/radvent:latest
    ports:
      - "3000:3000"
    volumes:
      - "$PWD/data:/var/radvent_data"
```

Thanks
--------

* [Yohei Koyama](https://github.com/nanonanomachine) Author of original radvent.

