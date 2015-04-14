require "open-uri"
require "nokogiri"
require "twitter_ebooks"

def trivia(page)
  trivia_header = page.css("#Trivia").first
  return unless trivia_header
  trivia_header.parent.css("~ ul:not(.gallery) > li").map(&:text).map(&:strip).reject(&:empty?)
end

def already_used?(trivia)
  false
end

def tweet_content(title, url, content)
  "#{title} #{url}\n#{content}"
end

def tweet_length(title, content)
  tweet_content(title, "", content).length + 22 # length of url
end

def random_trivia_from_page(page, url)
  title = page.css("#firstHeading").text
  options = trivia(page) || []
  options.reject! do |option|
    tweet_length(title, option) > 140 || already_used?(option)
  end
  options.map { |content| tweet_content(title, url, content) }
end

def random_trivia
  until option ||= nil
    response = open("http://bulbapedia.bulbagarden.net/wiki/Special:Random")
    page = Nokogiri::HTML response.read
    options = random_trivia_from_page(page, response.base_uri)
    option = options.sample
  end
  option
end

class Bulbatrivia < Ebooks::Bot
  def configure
    self.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
    self.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
    self.access_token = ENV["TWITTER_ACCESS_TOKEN"]
    self.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
  end

  def on_startup
    scheduler.every '2h' do
      tweet random_trivia
    end
    tweet random_trivia
  end
end

Bulbatrivia.new("bulbatrivia")
