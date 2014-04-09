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
      @html_fixtures = {}
      html_fixture_files = Dir.glob(File.join(File.dirname(__FILE__), "fixtures/*_html_fixtures.yml"))
      html_fixture_files.each { |file| @html_fixtures[File.basename(file)[0..-5]] = YAML::load(IO.read(file)).symbolize }
      @options = OpenStruct.new(skip_robots: false, max_page_depth: 10)
      @host = UrlHelper::get_normalized_host("http://www.nisdom.com")
      @start_url = UrlHelper::get_normalized_url(@host, "http://www.nisdom.com")
    end

    describe "test only robots.txt stuff" do
      before(:each) do
        @out = StringIO.new
        @crawler = Crawler.new(@out, @options)
      end

      context "when robots.txt can't be found" do
        it "should exit with 1" do
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
          @crawler.stub(:get_http_response).and_return(body: "<html></html>", code: 200, headers: { "Content-Type" => "text/html"})
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_allow_all], code: 200)
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return a single page" do
          @root.count.should eq 1
        end

        it "scraped? should return true" do
          @root.scraped?.should be_true
        end
      end

      context "when specific page is disallowed and we have anchor on start page" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: "<html><a href=\"/secret\"></a></html>", code: 200, headers: { "Content-Type" => "text/html"})
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_disallow_specific], code: 200)
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return 2 pages" do
          @root.count.should eq 2
        end

        it "scraped? should return true for the root page" do
          @root.scraped?.should be_true
        end

        it "scraped? should return false for the first child page" do
          @root.sub_pages[0].scraped?.should be_false
        end

        it "robots_forbidden? return true for the first child page" do
          @root.sub_pages[0].robots_forbidden?.should be_true
        end
      end

      context "when everything is allowed and we have anchor on start page" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: "<html></html>", code: 200, headers: { "Content-Type" => "text/html"})
          @crawler.stub(:get_http_response).with(Addressable::URI.parse("http://www.nisdom.com")).and_return(body: "<html><a href=\"/secret\"></a></html>", code: 200, headers: { "Content-Type" => "text/html"})
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_allow_all], code: 200)
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return 2 nodes" do
          @root.count.should eq 2
        end

        it "scraped? should return true for the root page" do
          @root.scraped?.should be_true
        end

        it "scraped? should return false for the first child page" do
          @root.sub_pages[0].scraped?.should be_true
        end
      end

      context "when ignored and we have anchor on start page" do
        before(:each) do
          @crawler.stub(:get_http_response).and_return(body: "<html></html>", code: 200, headers: { "Content-Type" => "text/html"})
          @crawler.stub(:get_http_response).with(Addressable::URI.parse("http://www.nisdom.com")).and_return(body: "<html><a href=\"/secret\"></a></html>", code: 200, headers: { "Content-Type" => "text/html"})
          @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_disallow_all], code: 200)
          @options.skip_robots = true
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return 2 nodes" do
          @root.count.should eq 2
        end

        it "scraped? should return true for the root page" do
          @root.scraped?.should be_true
        end

        it "scraped? should return false for the first child page" do
          @root.sub_pages[0].scraped?.should be_true
        end
      end
    end

    describe "test with some pre-baked html docs, with and without robots.txt" do
      before(:each) do
        @out = StringIO.new
        @crawler = Crawler.new(@out, @options)
        @crawler.stub(:get_http_response).and_return(body: nil, code: 404)
        @crawler.stub(:get_http_response).with(URI("http://www.nisdom.com/robots.txt")).and_return(body: @robots[:robots_allow_all], code: 200)
      end

      context "when called with traversal depth of 1" do
        before(:each) do
          @html_fixtures["d1_html_fixtures"].each do |url, html|
            url = UrlHelper::get_normalized_url(@host, url.to_s.tr("\"", ""))
            @crawler.stub(:get_http_response).with(url).and_return(body: html, code: 200, headers: { "Content-Type" => "text/html"})
          end
          @options.max_page_depth = 1
          @root = @crawler.start(@host, @start_url).first
        end

        it "should return 6 pages" do
          @root.count.should eq 6
        end

        it "should have correct scraping stop codes" do
          @root.scraped?.should be_true
          @root.sub_pages[0].depth_reached?.should be_true
          @root.sub_pages[1].depth_reached?.should be_true
          @root.sub_pages[2].external_domain?.should be_true
          @root.sub_pages[3].depth_reached?.should be_true
          @root.sub_pages[4].external_domain?.should be_true
        end
      end

      context "when called with traversal depth of 4" do
        before(:each) do
          @html_fixtures["d4_html_fixtures"].each do |url, html|
            url = UrlHelper::get_normalized_url(@host, url.to_s.tr("\"", ""))
            @crawler.stub(:get_http_response).with(url).and_return(body: html, code: 200, headers: { "Content-Type" => "text/html"})
          end
          @options.max_page_depth = 4
          @root = @crawler.start(@host, @start_url).first
        end

        it "count should return 40 pages starting from root page" do
          @root.count.should eq 40
        end

        it "scraped? should return true for the root page" do
          @root.scraped?.should be_true
        end

        it "scraped? should return true for the first child page" do
          @root.sub_pages[0].scraped?.should be_true
        end

        it "count should return 25 pages starting from the first child page" do
          @root.sub_pages[0].count.should eq 25
        end

        it "scraped? should return true for the second child page" do
          @root.sub_pages[1].scraped?.should be_true
        end

        it "count should return 6 pages starting from the second child page" do
          @root.sub_pages[1].count.should eq 6
        end

        it "external_domain? should return true for the third child page" do
          @root.sub_pages[2].external_domain?.should be_true
        end

        it "scraped? should return true for the fourth child page" do
          @root.sub_pages[3].scraped?.should be_true
        end
        
        it "count should return 6 pages starting from the fourth child page" do
          @root.sub_pages[3].count.should eq 6
        end

        it "external_domain? should return true for the fifth child page" do
          @root.sub_pages[4].external_domain?.should be_true
        end
      end
    end
  end
end
