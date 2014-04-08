require "spec_helper"
require_relative "../page"

module SiteMapper
  describe Page do
    context "initialize" do
      let(:page) { Page.new("http://www.nisdom.com/") }
    
      it "should have all static and sub-page collections initialized" do
        page.sub_pages.empty?.should be true
        page.anchors.empty?.should be true
        page.images.empty?.should be true
        page.links.empty?.should be true
        page.scripts.empty?.should be true
        page.count.should eq 1
        page.scraped?.should eq true
        page.non_scraped_code.should eq 0
        page.path.should eq "http://www.nisdom.com/"
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

    context "<<" do
      let(:page1) { ((Page.new("http://www.nisdom.com/") << Page.new("http://www.nisdom.com/1")) << Page.new("http://www.nisdom.com/2")) << Page.new("http://www.nisdom.com/3") }
      let(:page2) { Page.new("http://www.nisdom.com/") << (Page.new("http://www.nisdom.com/1") << (Page.new("http://www.nisdom.com/2") << Page.new("http://www.nisdom.com/3"))) }
      
      it "should return correct number of objects" do
        page1.count.should eq 4
        page1.sub_pages.count.should eq 3
        page1.sub_pages[0].count.should eq 1

        page2.count.should eq 4
        page2.sub_pages.count.should eq 1
        page2.sub_pages[0].count.should eq 3
      end
    end

    context "scraped?" do
      let(:page) { Page.new("http://www.nisdom.com/") }

      it "should return false" do
        page.non_scraped_code = Page::NON_SCRAPED_DEPTH
        page.scraped?.should eq false
      end

      it "should return true" do
        page.non_scraped_code = 0
        page.scraped?.should eq true
      end
    end
  end
end
