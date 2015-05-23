require "twitter_ebooks"
require_relative "../bulbapedia"
require_relative "trivia_manager"

module Bulbatrivia
  class Bot < Ebooks::Bot
    MAX_TWEET_LENGTH = 140

    # various formats a tweet can be in,
    # in order of preference.
    FORMATS = [
      "%{title} %{url}\n%{content}",
      "%{title}\n%{content}",
      "%{content}\n%{url}",
      "%{content}",
    ]

    ERROR_FORMATS = [
      "Bulbapedia doesn't have an article about %{term}.",
      "Bulbapedia doesn't have an article about that.",
    ]

    def configure
      # no-op
      # configuration will be handled by bot owner
    end

    def initialize(*)
      super

      @scheduled_trivia_manager = TriviaManager.new do |trivium|
        content = trivium[:content]
        !content.include?(?:) && content.length <= MAX_TWEET_LENGTH
      end

      @mention_client = Bulbapedia::Client.new
      @mention_trivia_manager = TriviaManager.new do |trivium|
        content = trivium[:content]
        next false if content.include? ?:
        next false if (@reply_prefix + content).length > MAX_TWEET_LENGTH
        true
      end
    end

    def on_startup
      scheduler.every '1h' do
        trivium = @scheduled_trivia_manager.random_trivium
        tweet format_tweet(trivium)
        unfollow_unfollers
      end
    end

    def on_follow(user)
      follow(user.screen_name)
    end

    def on_mention(mention)
      text = meta(mention).mentionless
      @reply_prefix = meta(mention).reply_prefix
      length = MAX_TWEET_LENGTH - @reply_prefix.length
      page = @mention_client.search(text)[0]

      response = if page
        # if page has no trivia, format with a dummy trivium, then remove the
        # last line, so the tweet is the title of the article and a link.
        trivium = @mention_trivia_manager.trivia(page: page).sample
        no_trivia = trivium.nil?
        trivium ||= { url: page.url, title: page.title, content: "" }
        trivium[:url] << "#Trivia"
        format_tweet(trivium, length: length).tap { |t| t.strip! if no_trivia }
      else
        format_tweet({term: text}, length: length, formats: ERROR_FORMATS)
      end

      reply mention, @reply_prefix + response
    end

    def unfollow_unfollers
      unfollowers = twitter.following.map(&:id) - twitter.followers.map(&:id)
      twitter.unfollow(*unfollowers)
    end

    protected

    def format_tweet(args, length: MAX_TWEET_LENGTH, formats: FORMATS)
      sub_url = ?a * 22 # on Twitter, all URLs are 22 characters
      length_args = args.merge(url: sub_url)
      format = formats.select do |format|
        (format % length_args).length <= length
      end.first
      puts "Chose format #{format.inspect} for arguments: #{args.inspect}"
      format % args
    end
  end
end
