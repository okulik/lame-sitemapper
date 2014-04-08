module SiteMapper
  class Page
    attr_accessor :path
    attr_reader :sub_pages
    attr_reader :anchors
    attr_reader :images
    attr_reader :links
    attr_reader :scripts
    attr_accessor :non_scraped_code

    NON_SCRAPED_DEPTH = 1
    NON_SCRAPED_DOMAIN = 2
    NON_SCRAPED_ROBOTS = 4

    def initialize(path)
      @path = path
      @sub_pages = []
      @anchors = []
      @images = []
      @links = []
      @scripts = []
      @non_scraped_code = 0
    end

    def count
      self.each.count
    end

    def <<(page)
      @sub_pages << page
      self
    end

    def scraped?
      @non_scraped_code == 0
    end

    def format_codes
      reasons = []
      reasons << "depth" if (@non_scraped_code & Page::NON_SCRAPED_DEPTH) > 0
      reasons << "robots" if (@non_scraped_code & Page::NON_SCRAPED_ROBOTS) > 0
      reasons << "ext" if (@non_scraped_code & Page::NON_SCRAPED_DOMAIN) > 0
      reasons.join("|")
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      yield self
      @sub_pages.each { |p| p.each(&block) }
    end
  end
end
