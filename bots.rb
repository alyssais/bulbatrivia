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

def random_trivia_from_page(page)
  title = page.css("#firstHeading").text
  options = trivia(page) || []
  options.map! { |option| "#{title}: #{option}" }
  options.reject { |option| option.length > 140 || already_used?(option) }
end

def random_trivia
  response = nil
  until option ||= nil
    response = open("http://bulbapedia.bulbagarden.net/wiki/Special:Random")
    page = Nokogiri::HTML response.read
    options = random_trivia_from_page(page)
    option = options.sample
  end
  option += " #{response.base_uri}" if option.length <= 117
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
  end
end

Bulbatrivia.new("bulbatrivia")
