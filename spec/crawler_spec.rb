require "yaml"
require "ostruct"
require "spec_helper"
require_relative "../config/patch"
require_relative "../config/init_settings"
require_relative "../config/init_logger"
require_relative "../crawler"

module SiteMapper
  describe Crawler do
    before(:all) do
      @robots = YAML::load(IO.read(File.join(File.dirname(__FILE__), "fixtures/robots_fixtures.yml"))).symbolize
      @out = StringIO.new
      @options = OpenStruct.new(skip_robots: false, max_page_depth: 10)
      @host = UrlHelper::get_normalized_host("http://www.nisdom.com")
      @start_url = UrlHelper::get_normalized_url(@host, "http://www.nisdom.com")
    end

    before(:each) do
      @crawler = Crawler.new(@out, @options)
    end

    describe "test robots.txt stuff" do
      context "when robots.txt can't be found" do
        it "should exit with -1" do
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: nil, code: 404)
          lambda { @crawler.start(@host, @start_url) }.should exit_with_code(1)
        end
      end

      context "when everything is disallowed" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: nil, code: 200)
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_disallow_all], code: 200)
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return robots_forbidden? true" do
          @root.robots_forbidden?.should be_true
        end
      end

      context "when evertything is allowed" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: "<html></html>", code: 200)
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_allow_all], code: 200)
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return a tree with a single node" do
          @root.count.should eq 1
          @root.scraped?.should be_true
        end
      end

      context "when specific page is disallowed and we have anchor on start page" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: "<html><a href=\"/secret\"></a></html>", code: 200)
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_disallow_specific], code: 200)
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return tree with two nodes" do
          @root.count.should eq 2
          @root.scraped?.should be_true
          @root.sub_pages[0].scraped?.should be_false
          @root.sub_pages[0].robots_forbidden?.should be_true
        end
      end

      context "when everything is allowed and we have anchor on start page" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: "<html></html>", code: 200)
          @crawler.stub(:get_http_response).with(Addressable::URI.parse("http://www.nisdom.com")).and_return(body: "<html><a href=\"/secret\"></a></html>", code: 200)
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_allow_all], code: 200)
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return tree with two nodes" do
          @root.count.should eq 2
          @root.scraped?.should be_true
          @root.sub_pages[0].scraped?.should be_true
        end
      end

      context "when ignored and we have anchor on start page" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: "<html></html>", code: 200)
          @crawler.stub(:get_http_response).with(Addressable::URI.parse("http://www.nisdom.com")).and_return(body: "<html><a href=\"/secret\"></a></html>", code: 200)
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_disallow_all], code: 200)
          @options.skip_robots = true
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return tree with two nodes" do
          @root.count.should eq 2
          @root.scraped?.should be_true
          @root.sub_pages[0].scraped?.should be_true
        end
      end
    end
  end
end
