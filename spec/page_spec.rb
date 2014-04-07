require 'spec_helper'
require_relative '../page'

module SiteMapper
  describe Page do
    context "initialize" do
      let(:page) { Page.new('http://www.nisdom.com/') }
    
      it "should have all static and sub-page collections initialized" do
        page.sub_pages.empty?.should be true
        page.images.empty?.should be true
        page.links.empty?.should be true
        page.scripts.empty?.should be true
        page.count.should eq 1
        page.path.should eq 'http://www.nisdom.com/'
      end
    end

    context "count" do
      let(:page) do
        p = Page.new('http://www.nisdom.com/')
        p.sub_pages << Page.new('http://www.nisdom.com/1')
        p.sub_pages << Page.new('http://www.nisdom.com/2')
        p
      end

      it "should return true" do
        page.count.should eq 3
      end
    end
  end
end
