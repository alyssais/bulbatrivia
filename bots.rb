require "open-uri"
require "nokogiri"
require "twitter_ebooks"
require "rest-client"
require "redis"

Bulbapedia = RestClient::Resource.new("http://bulbapedia.bulbagarden.net")

class SearchResult < Struct.new(:title, :href)
  def get
    Bulbapedia[href].get
  end
end

class << Bulbapedia
  def go(term)
    self["w/index.php"].get params: { search: term }
  end

  def search(term)
    self["w/index.php"].get params: { search: term, fulltext: "Search" }
  end

  def search_results(term)
    Nokogiri::HTML(search(term)).css(".mw-search-result-heading a").map do |a|
      SearchResult.new(a.text, a.attr(:href))
    end
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
  items = lists.map { |e| e.css("> li").map { |li| li.text.split("\n").first.strip } }.flatten
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
  options.reject! do |option|
    format.%(title: title, content: option, url: ?a * 22).length > 140
  end
  format_args = { title: title, url: response.request.url }
  options.map { |content| format % format_args.merge(content: content) }
end

def random_trivium
  until option ||= nil
    response = Bulbapedia["wiki/Special:Random"].get
    options = trivia_from_response(response)
    options.reject! { |trivium| already_used?(trivium) }
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

  def on_timeline(tweet)
    Bulbapedia.search_results(meta(tweet).mentionless).each do |result|
      title = result.title.gsub(/\([^\)]*\)/, "").strip
      if meta(tweet).mentionless.downcase[title.downcase]
        reply_to(tweet: tweet, response: result.get)
        break
      end
    end
  end

  def on_mention(mention)
    text = meta(mention).mentionless
    text.gsub! /\A\./, ""
    return if text.start_with? "—" # like a comment!
    response = Bulbapedia.search_results(text).first.get

    if response.request.url.start_with? "http://bulbapedia.bulbagarden.net/w/index.php"
      answer = meta(mention).reply_prefix + "Bulbapedia doesn't have an article about "
      answer += answer.length + text.length > 140 ? "that" : text
      reply mention, answer
      return
    end

    reply_to(tweet: mention, response: response, allow_url_only: true)
  end

  protected

  def reply_to(tweet:, response:, allow_url_only: false)
    prefix = meta(tweet).reply_prefix
    options = trivia_from_response(response, format: "#{prefix}%{content}")
    answer = options.sample || ""
    answer += " #{response.request.url}#Trivia" if answer.length <= 117 && (answer != "" || allow_url_only)
    reply tweet, answer
  end
end

Bulbatrivia.new("bulbatrivia")
