require "open-uri"
require "nokogiri"
require "twitter_ebooks"
require "rest-client"
require "redis"

Bulbapedia = RestClient::Resource.new("http://bulbapedia.bulbagarden.net")

class << Bulbapedia
  def go(term)
    self["w/index.php"].get params: { search: term }
  end

  def search(term)
    self["w/index.php"].get params: { search: term, fulltext: "Search" }
  end

  def first_search_result(term)
    index = Nokogiri::HTML search(term).to_str
    self[index.css(".mw-search-result-heading a").first.attr("href")].get
  end
end

def trivia(page)
  trivia_header_span = page.css("#Trivia").first
  return unless trivia_header_span
  siblings = trivia_header_span.parent.css("~ *")
  section_content = siblings.slice_before { |e| e.name == "h2" }.first
  lists = section_content.select do |e|
    %w(ol ul).include?(e.name) && e.matches?(":not([class])")
  end
  items = lists.map { |e| e.css("> li").text.split("\n").first.strip }.flatten
  items.reject { |item| item.empty? || item.end_with?(?:) }
end

def redis
  $redis ||= Redis.new(url: ENV["REDISTOGO_URL"])
end

def already_used?(trivium)
  redis.sismember(:tweets, trivium)
end

def use!(trivium)
  redis.sadd(:tweets, trivium)
end

def trivia_from_response(response, format: "%{title} %{url}\n%{content}")
  page = Nokogiri::HTML(response.to_str)
  page.css("sup").remove
  title = page.css("#firstHeading").text
  options = trivia(page) || []
  format_args = { title: title, url: response.request.url }
  options.map { |content| format % format_args.merge(content: content) }
end

def random_trivium
  until option ||= nil
    response = Bulbapedia["wiki/Special:Random"].get
    options = trivia_from_response(response)
    options.reject! do |trivium|
      already_used?(trivium)
    end
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
    scheduler.every '1h' do
      trivium = random_trivium
      tweet trivium
      use! trivium
    end
  end

  def on_follow(user)
    follow(user.screen_name)
  end

  def on_mention(mention)
    text = meta(mention).mentionless
    text.gsub! /\A\./, ""
    return if text.start_with? "—" # like a comment!
    response = Bulbapedia.first_search_result(text)
    if response.request.url.start_with? "http://bulbapedia.bulbagarden.net/w/index.php"
      answer = meta(mention).reply_prefix + "Bulbapedia doesn't have an article about "
      answer += answer.length + text.length > 140 ? "that" : text
      reply mention, answer
      return
    end

    options = trivia_from_response(response, format: "%{content}")
    answer = meta(mention).reply_prefix
    answer += options.sample || ""
    answer += " #{response.request.url}#Trivia" if answer.length <= 117
    answer.gsub! "  ", " "
    reply mention, answer
  end
end

Bulbatrivia.new("bulbatrivia")
