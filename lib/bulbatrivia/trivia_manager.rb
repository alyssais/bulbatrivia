require_relative "../bulbapedia"

module Bulbatrivia
  class TriviaManager
    def initialize(&predicate)
      @client = Bulbapedia::Client.new
      @predicate = predicate
    end

    def random_trivium
      url = nil
      title = nil
      @cached_trivia ||= []

      while @cached_trivia.empty?
        page = @client.random_page
        @cached_trivia = trivia(page: page).shuffle
      end

      { url: url, title: title, content: @cached_trivia.pop }
    end

    def trivia(page:)
      trivia = (page.trivia || []).map do |content|
        # create trivia objects
        { url: page.url, title: page.title, content: content }
      end.select(&@predicate) # apply constraints
    end
  end
end
