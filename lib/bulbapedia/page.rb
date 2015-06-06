module Bulbapedia
  class Page
    attr :mechanize_page
    attr :url
    attr :title

    def initialize(mechanize_page)
      @mechanize_page = mechanize_page
      @url = mechanize_page.uri.to_s
      @title = mechanize_page.search("#firstHeading").text
    end

    def trivia
      # locate the "Trivia" header, the start of the section
      trivia_header_span = mechanize_page.search("#Trivia").first
      return if trivia_header_span.nil?

      # find content of the Trivia section — it lies between the Trivia
      # header and the next h2.
      siblings = trivia_header_span.parent.css("~ *")
      trivia_content = siblings.slice_before { |e| e.name == "h2" }.first

      # extract lists of trivia
      # if a list has a class applied it is a gallery or similar,
      # not text trivia.
      wrappers = trivia_content.select do |e|
        %w(p ol ul).include?(e.name) && e.matches?(":not([class])")
      end

      # extract content of trivia from wrappers
      items = wrappers.map do |wrapper|
        # remove sub-trivia
        (wrapper.name == ?p ? [wrapper] : wrapper.css("> li")).map do |node|
          node = node.dup # don't modify the original node

          # replace images with alt text
          node.css("img").each { |img| img.swap(img[:alt]) }

          # remove sub-trivia
          node.tap { |n| n.css("li").remove }.text.strip
        end.reject(&:empty?)
      end.flatten

      items.reject { |item| item.empty? || item.end_with?(?:) }
    end
  end
end
