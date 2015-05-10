require "twitter_ebooks"

require_relative "trivia_manager"

module Bulbatrivia
  class Bot < Ebooks::Bot
    FORMATS = [
      "%{title} %{url}\n%{content}",
      "%{title}\n%{content}",
      "%{content}\n%{url}",
      "%{content}",
    ]

    def configure
      self.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
      self.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
      self.access_token = ENV["TWITTER_ACCESS_TOKEN"]
      self.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
    end

    def on_startup
      @scheduled_trivia_manager = TriviaManager.new do |trivium|
        !trivium.include?(?:) && trivium.length <= 140
      end

      # scheduler.every '5s' do
        trivium = @scheduled_trivia_manager.random_trivium
        puts format_tweet(trivium)
      # end
    end

    def format_tweet(args)
      sub_url = ?a * 22 # on Twitter, all URLs are 22 characters
      length_args = args.merge(url: sub_url)
      format = FORMATS.select do |format|
        (format % length_args).length <= 140
      end.first
      format % args
    end
  end
end
