require "spec_helper"
require_relative "../page"

module SiteMapper
  describe Page do
    context "initialize" do
      let(:page) { Page.new('http://www.nisdom.com/') }
    
      it "should have all static and sub-page collections initialized" do
        page.sub_pages.empty?.should be true
        page.anchors.empty?.should be true
        page.images.empty?.should be true
        page.links.empty?.should be true
        page.scripts.empty?.should be true
        page.count.should eq 1
        page.scraped?.should eq false
        page.path.should eq 'http://www.nisdom.com/'
      end
    end

    context "count" do
      let(:page) { Page.new("http://www.nisdom.com/") << Page.new("http://www.nisdom.com/1") << Page.new("http://www.nisdom.com/2") << Page.new("http://www.nisdom.com/3") }
      it "should return 4 nodes" do
        page.count.should eq 4
      end
    end

    context "each" do
      let(:page) { Page.new("http://www.nisdom.com/") << Page.new("http://www.nisdom.com/1") << Page.new("http://www.nisdom.com/2") << Page.new("http://www.nisdom.com/3") }
      it "should return 4 nodes" do
        counter = 0
        page.each { |p| counter += 1 }
        counter.should eq 4
      end
    end
  end
end
