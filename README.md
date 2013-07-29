twirc
=====

# できること
tweet拾ってきて、IRCに投下する。
tweet引っ張ってくる部分は https://github.com/sferik/twitter


# 使い方
これでいけるかな..

    cd twirc/
    bundle install --path vender/bundle
    vim .config/irc.yaml
    vim .config/twitter.yaml
    bundle exec ruby twirc.rb production


# やりたいこと
* 適当なGUI作ってそっからいろいろ設定(アカウント設定とか)
* エラー対応 -> `Twitter::Error::ClientErrorTimeout::Error`
* ログ綺麗にしてファイル出力
