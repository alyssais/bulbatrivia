$:.unshift File.expand_path("#{__dir__}/..")
require "bulbapedia"

module Bulbatrivia
  class TriviaManager
    attr_accessor :trivia_constraints

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
        url = page.url
        title = page.title
        @cached_trivia = (page.trivia || []).shuffle
        apply_constraints!(@cached_trivia)
      end

      { url: url, title: title, content: @cached_trivia.pop }
    end

    private

    def apply_constraints!(trivia)
      trivia.select!(&@predicate)
    end
  end
end
