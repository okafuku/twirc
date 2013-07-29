#!/usr/bin/env ruby
# encoding: utf-8

base_path = File.join(File.dirname(File.expand_path( __FILE__)), "/")
$: <<  base_path

require 'twitter'
require 'yaml'
require 'lib/irc'


env = ARGV[0] || 'development'
irc_conf = YAML.load_file(base_path + "config/irc.yaml")[env]
twitter_conf = YAML.load_file(base_path + "config/twitter.yaml")['default']
threads = []
msgs = []
latest_tweet_id_filepath = base_path + "/tmp/latest_tweet_id.txt"

latest_tweet_id = 
  if File.exist?(latest_tweet_id_filepath)
    File.read(latest_tweet_id_filepath, :encoding => Encoding::UTF_8).to_i
  else
    0
  end

### irc
host        = irc_conf['host']
port        = irc_conf['port']
#password    = irc_conf['password']
nickname    = irc_conf['nickname']
login_name  = irc_conf['login_name']
name        = irc_conf['name']
channel     = irc_conf['channel']
charcode    = irc_conf['charcode']

irc_client = Irc.new(host, port, name, login_name, nickname, charcode)
threads << irc_client.connect
irc_client.join(channel)

irc_client.privmsg(channel, "start twirc with #{env} mode")


### twitter
Twitter.configure do |config|
  config.consumer_key       = twitter_conf['app']['consumer_key']
  config.consumer_secret    = twitter_conf['app']['consumer_secret']
  config.oauth_token        = twitter_conf['account']['oauth_token']
  config.oauth_token_secret = twitter_conf['account']['oauth_token_secret']
end


# target
#query = "ruby ルビー"
#options = { :lang => 'ja',
#            :count => 100 }

interval = 60 * 5
begin
  threads << Thread.new do
    loop do

      begin
        tweets = Twitter.home_timeline
        ### 検索
        #tweets = Twitter.search(query, options).results
        ### リスト
        #tweets = Twitter.list_timeline("twitter_account_name", "list_name")
        puts "get #{tweets.size} tweets!!"
      rescue => e
        irc_client.privmsg(channel, "[error] " + e.class.to_s + e.message)
        irc_client.privmsg(channel, "I sleep 15min")
        sleep 60*15
        next
      end


      tweets.each do |tweet|
        if tweet.id > latest_tweet_id
          #出力例 : 12:04 [@okafuku] テスト
          msgs << "#{tweet.created_at.strftime("%H:%M")} [@#{tweet.user.screen_name}] #{tweet.text.gsub("\n", " ")}"
        else
          #msgs << "no new tweets ;_;" if msgs.size == 0
          break
        end
      end

      while msgs.size > 0
        irc_client.privmsg(channel, msgs.pop)
        sleep 1
      end


      latest_tweet_id = tweets.first.id
      File.open(latest_tweet_id_filepath, "w+") { |f| f.puts latest_tweet_id }
      
      sleep interval
    end
  end
rescue
  puts "[log] unhandled exception @ twitter thread"
end



### start
threads.each { |th| th.join }
