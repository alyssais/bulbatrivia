require_relative "page"

module Bulbapedia
  class Search
    include Enumerable

    RESULT_LINK_SELECTOR = ".mw-search-result-heading a"

    def initialize(term, client, limit: 20)
      @term = term
      @client = client
      @limit = limit
    end

    def [](index)
      @results ||= {}
      @results[index] ||= begin
        page_index = index / @limit
        index_on_page = index % @limit
        link = results_for(page: page(page_index))[index_on_page]
        Page.new(@client.agent.click(link)) unless link.nil?
      end
    end

    def each
      i = -1
      while page = self[i += 1]
        yield page
      end
    end

    def load(page:)
      result = @client.get(
        search: @term,
        fulltext: "Search",
        limit: @limit,
        offset: @limit * (page - 1),
      ).mechanize_page
      @pages ||= {}
      @pages[page] ||= result
      nil
    end

    def results
      load(page: 0) if @pages.nil?
      @pages.values.map { |page| results_for(page: page) }.flatten
    end

    protected

    def results_for(page:)
      page.search(RESULT_LINK_SELECTOR).map(&:to_h)
    end

    def page(index)
      load(page: index)
      @pages[index]
    end
  end
end
