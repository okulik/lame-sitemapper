module SiteMapper
  class Page
    attr_accessor :path
    attr_reader :sub_pages
    attr_reader :anchors
    attr_reader :images
    attr_reader :links
    attr_reader :scripts

    def initialize(path)
      @path = path
      @sub_pages = []
      @anchors = []
      @images = []
      @links = []
      @scripts = []
      @scraped = false
    end

    def count
      self.each.count
    end

    def <<(page)
      @sub_pages << page
      self
    end

    def scraped?
      @scraped
    end

    def scraped=(value)
      @scraped = value
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      yield self
      @sub_pages.each { |p| p.each(&block) }
    end
  end
end
