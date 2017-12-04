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

[![Docker build](http://dockeri.co/image/haru/radvent)](https://registry.hub.docker.com/u/haru/radvent/)

### Start container with docker command

```
$ docker run -d -p 3000:3000 -v /host/data/directory:/var/radvent_data haru/radvent
```

### docker-compose.yml example

example with mysql.

```yaml
version: '2'
services:
  radvent:
    image: haru/radvent:latest
    ports:
      - "3000:3000"
    volumes:
      - "$PWD/docker/data:/var/radvent_data"
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
    environment:
      MYSQL_ROOT_PASSWORD: example
    volumes:
      - "$PWD/docker/mysql:/var/lib/mysql"
```

example with postgresql.

```yaml
version: '2'
services:
  radvent:
    image: haru/radvent:latest
    ports:
      - "3000:3000"
    volumes:
      - "$PWD/docker/data:/var/radvent_data"
    links:
      - postgres
    environment:
      DB: postgres
      DB_USERNAME: postgres
      DB_PASSWORD: example
      DB_HOST: postgres
      DB_CREATE_ON_START: "true"
  postgres:
    image: postgres
    environment:
      POSTGRES_PASSWORD: example
    volumes:
      - "$PWD/docker/postgres:/var/lib/postgresql/data"
```

### environment variables

| key               | value                     |     default                       |
|-------------------|---------------------------|:----------------------------------|
| DB                | sqlite3, mysqsl, postgres |     sqlite3                       |
| DB_NAME           | name of database          |     radvent                       |
| DB_USERNAME       | username of dbms          |        -                          |
| DB_PASSWORD       | password of dbms          |        -                          |
| DB_HOST           | hostname of dbms          |        -                          |
| DB_PORT           | port of dbms              | 3306 for mysql, 5432 for postgres |
| DB_CREATE_ON_START| true: execute rake db:create when starting conainer. | false  |


Thanks
--------

* [Yohei Koyama](https://github.com/nanonanomachine) Author of original radvent.

