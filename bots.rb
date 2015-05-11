require_relative "lib/bulbatrivia"

Bulbatrivia::Bot.new(ENV["TWITTER_USERNAME"]) do |bot|
  bot.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
  bot.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
  bot.access_token = ENV["TWITTER_ACCESS_TOKEN"]
  bot.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
end
