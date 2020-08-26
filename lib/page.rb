# frozen_string_literal: true

module Sitemapper
  class Page
    extend Forwardable

    def_delegators :@sub_pages, :<<
    def_delegators :each, :count

    attr_accessor :path
    attr_reader :sub_pages
    attr_reader :anchors
    attr_reader :images
    attr_reader :links
    attr_reader :scripts

    NON_SCRAPED_DEPTH = 1
    NON_SCRAPED_DOMAIN = 2
    NON_SCRAPED_ROBOTS = 4
    NON_SCRAPED_NO_HTML = 8
    NON_SCRAPED_NOT_ACCESSIBLE = 16

    def initialize(path)
      @path = path
      @sub_pages = []
      @anchors = []
      @images = []
      @links = []
      @scripts = []
      @non_scraped_code = 0
    end

    def scraped?
      @non_scraped_code == 0
    end

    def robots_forbidden?
      @non_scraped_code & Page::NON_SCRAPED_ROBOTS > 0
    end

    def robots_forbidden=(value)
      if value
        @non_scraped_code |= Page::NON_SCRAPED_ROBOTS
      else
        @non_scraped_code &= ~Page::NON_SCRAPED_ROBOTS
      end
    end

    def external_domain?
      @non_scraped_code & Page::NON_SCRAPED_DOMAIN > 0
    end

    def external_domain=(value)
      if value
        @non_scraped_code |= Page::NON_SCRAPED_DOMAIN
      else
        @non_scraped_code &= ~Page::NON_SCRAPED_DOMAIN
      end
    end

    def depth_reached?
      @non_scraped_code & Page::NON_SCRAPED_DEPTH > 0
    end

    def depth_reached=(value)
      if value
        @non_scraped_code |= Page::NON_SCRAPED_DEPTH
      else
        @non_scraped_code &= ~Page::NON_SCRAPED_DEPTH
      end
    end

    def no_html?
      @non_scraped_code & Page::NON_SCRAPED_NO_HTML > 0
    end

    def no_html=(value)
      if value
        @non_scraped_code |= Page::NON_SCRAPED_NO_HTML
      else
        @non_scraped_code &= ~Page::NON_SCRAPED_NO_HTML
      end
    end

    def not_accessible?
      @non_scraped_code & Page::NON_SCRAPED_NOT_ACCESSIBLE > 0
    end

    def not_accessible=(value)
      if value
        @non_scraped_code |= Page::NON_SCRAPED_NOT_ACCESSIBLE
      else
        @non_scraped_code &= ~Page::NON_SCRAPED_NOT_ACCESSIBLE
      end
    end

    def format_codes
      reasons = []

      reasons << "depth" if depth_reached?
      reasons << "robots" if robots_forbidden?
      reasons << "ext" if external_domain?
      reasons << "nohtml" if no_html?
      reasons << "noacc" if not_accessible?

      "#{reasons.join('|')} "
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      yield self
      @sub_pages.each { |p| p.each(&block) }
    end

  end
end
