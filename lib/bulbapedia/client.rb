require "mechanize"

module Bulbapedia
  class Client
    BASE_URI = "http://bulbapedia.bulbagarden.net/w/index.php"

    attr :agent

    def initialize
      @agent = Mechanize.new
    end

    def random_page
      go("Special:Random")
    end

    def go(term)
      get(search: term)
    end

    def search(term)
      Search.new(term, self)
    end

    def get(args)
      Page.new(agent.get(BASE_URI, args))
    end

    def click(*args)
      agent.click(*args)
    end
  end
end
