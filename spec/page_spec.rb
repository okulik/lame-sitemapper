require "spec_helper"
require_relative "../page"

module SiteMapper
  describe Page do
    context "initialize" do
      let(:page) { Page.new("http://www.nisdom.com/") }
    
      it "should have all static and sub-page collections initialized" do
        page.sub_pages.empty?.should be_true
        page.anchors.empty?.should be_true
        page.images.empty?.should be_true
        page.links.empty?.should be_true
        page.scripts.empty?.should be_true
        page.count.should eq 1
        page.scraped?.should be_true
        page.robots_forbidden?.should be_false
        page.external_domain?.should be_false
        page.depth_reached?.should be_false
        page.no_html?.should be_false
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

      it "should test for various reasons scraping was stopped and return false" do
        page.depth_reached = true
        page.scraped?.should be_false
        
        page.external_domain = true
        page.scraped?.should be_false
        
        page.robots_forbidden = true
        page.scraped?.should be_false

        page.no_html = true
        page.scraped?.should be_false
      end

      it "should return true" do
        page.robots_forbidden = page.external_domain = page.depth_reached = page.no_html = false
        page.scraped?.should be_true
      end
    end

    context "bitfield backed getters and setters" do
      let(:page) { Page.new("http://www.nisdom.com/") }

      it "should return true whenever getter is matched to previously called setetr" do
        page.depth_reached = true
        page.depth_reached?.should be_true
        page.depth_reached = false
        page.depth_reached?.should be_false
        
        page.external_domain = true
        page.external_domain?.should be_true
        page.external_domain = false
        page.external_domain?.should be_false
        
        page.robots_forbidden = true
        page.robots_forbidden?.should be_true
        page.robots_forbidden = false
        page.robots_forbidden?.should be_false

        page.no_html = true
        page.no_html?.should be_true
        page.no_html = false
        page.no_html?.should be_false
      end
    end
  end
end
