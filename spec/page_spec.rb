# frozen_string_literal: true

require "spec_helper"

describe LameSitemapper::Page do
  context "initialize" do
    let(:page) { described_class.new("http://www.nisdom.com/") }
  
    it "should have all static and sub-page collections initialized" do
      expect(page.sub_pages.empty?).to eq(true)
      expect(page.anchors.empty?).to eq(true)
      expect(page.images.empty?).to eq(true)
      expect(page.links.empty?).to eq(true)
      expect(page.scripts.empty?).to eq(true)
      expect(page.count).to eq(1)
      expect(page.scraped?).to eq(true)
      expect(page.robots_forbidden?).to eq(false)
      expect(page.external_domain?).to eq(false)
      expect(page.depth_reached?).to eq(false)
      expect(page.no_html?).to eq(false)
      expect(page.not_accessible?).to eq(false)
      expect(page.path).to eq("http://www.nisdom.com/")
    end
  end

  context "count" do
    let(:page) { described_class.new("http://www.nisdom.com/") << described_class.new("http://www.nisdom.com/1") << described_class.new("http://www.nisdom.com/2") << described_class.new("http://www.nisdom.com/3") }
    
    it "returns 4 nodes" do
      expect(page.count).to eq(4)
    end
  end

  context "each" do
    let(:page) { described_class.new("http://www.nisdom.com/") << described_class.new("http://www.nisdom.com/1") << described_class.new("http://www.nisdom.com/2") << described_class.new("http://www.nisdom.com/3") }
    
    it "returns 4 nodes" do
      counter = 0
      page.each { |p| counter += 1 }
      expect(page.count).to eq(4)
    end
  end

  context "<<" do
    let(:page1) { ((described_class.new("http://www.nisdom.com/") << described_class.new("http://www.nisdom.com/1")) << described_class.new("http://www.nisdom.com/2")) << described_class.new("http://www.nisdom.com/3") }
    let(:page2) { described_class.new("http://www.nisdom.com/") << (described_class.new("http://www.nisdom.com/1") << (described_class.new("http://www.nisdom.com/2") << described_class.new("http://www.nisdom.com/3"))) }
    
    it "returns correct number of objects" do
      expect(page1.count).to eq(4)
      expect(page1.sub_pages.count).to eq(3)
      expect(page1.sub_pages[0].count).to eq(1)

      expect(page2.count).to eq(4)
      expect(page2.sub_pages.count).to eq(1)
      expect(page2.sub_pages[0].count).to eq(3)
    end
  end

  context "scraped?" do
    let(:page) { described_class.new("http://www.nisdom.com/") }

    it "should test for various reasons scraping was stopped and return false" do
      page.depth_reached = true
      expect(page.scraped?).to eq(false)
      
      page.external_domain = true
      expect(page.scraped?).to eq(false)
      
      page.robots_forbidden = true
      expect(page.scraped?).to eq(false)

      page.no_html = true
      expect(page.scraped?).to eq(false)

      page.not_accessible = true
      expect(page.scraped?).to eq(false)
    end

    it "returns true" do
      page.robots_forbidden = page.external_domain = page.depth_reached = page.no_html = false
      expect(page.scraped?).to eq(true)
    end
  end

  context "bitfield backed getters and setters" do
    let(:page) { described_class.new("http://www.nisdom.com/") }

    it "returns true whenever getter is matched to previously called setter" do
      page.depth_reached = true
      expect(page.depth_reached?).to eq(true)
      page.depth_reached = false
      expect(page.depth_reached?).to eq(false)
      
      page.external_domain = true
      expect(page.external_domain?).to eq(true)
      page.external_domain = false
      expect(page.external_domain?).to eq(false)
      
      page.robots_forbidden = true
      expect(page.robots_forbidden?).to eq(true)
      page.robots_forbidden = false
      expect(page.robots_forbidden?).to eq(false)

      page.no_html = true
      expect(page.no_html?).to eq(true)
      page.no_html = false
      expect(page.no_html?).to eq(false)

      page.not_accessible = true
      expect(page.not_accessible?).to eq(true)
      page.not_accessible = false
      expect(page.not_accessible?).to eq(false)
    end
  end
end
