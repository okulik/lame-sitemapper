require "spec_helper"

module SiteMapper
  describe Core do
    before(:all) do
      @robots = YAML::load(IO.read(File.join(File.dirname(__FILE__), "fixtures/robots_fixtures.yml"))).symbolize

      @html_fixtures = {}

      html_fixture_files = Dir.glob(File.join(File.dirname(__FILE__), "fixtures/*_html_fixtures.yml"))
      html_fixture_files.each { |file| @html_fixtures[File.basename(file)[0..-5]] = YAML::load(IO.read(file)).symbolize }

      @options = OpenStruct.new
      @options.use_robots = SETTINGS[:use_robots]
      @options.max_page_depth = SETTINGS[:max_page_depth]
      @options.log_level = SETTINGS[:log_level]
      @options.report_type = SETTINGS[:report_type]
      @options.frequency_type = SETTINGS[:sitemap_frequency_type]
      @options.scraper_threads = SETTINGS[:scraper_threads].to_i

      @host = UrlHelper::get_normalized_host("http://www.nisdom.com")
      @start_url = UrlHelper::get_normalized_url(@host, "http://www.nisdom.com")
    end

    describe "test only robots.txt stuff" do
      before(:each) do
        @out = StringIO.new
        @core = Core.new(@out, @options)
      end

      context "when robots.txt can't be found" do
        it "start method should return nil" do
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: nil, code: 404))
          @core.start(@host, @start_url).first.should be_nil
        end
      end

      context "when robots.txt disallows everything" do
        before(:each) do
          @options.use_robots = true
          Typhoeus.stub(@start_url.to_s).and_return(Typhoeus::Response.new(body: "<html></html>", code: 200))
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_disallow_all], code: 200))
          @root = @core.start(@host, @start_url).first
        end

        it "should return robots_forbidden? true" do
          @root.robots_forbidden?.should be_true
        end
      end

      context "when robots.txt allows everything" do
        before(:each) do
          @options.use_robots = true
          Typhoeus.stub(@start_url.to_s).and_return(Typhoeus::Response.new(body: "<html></html>", code: 200, headers: { "Content-Type" => "text/html"}))
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_allow_all], code: 200))
          @root = @core.start(@host, @start_url).first
        end

        it "should return a single page" do
          @root.count.should eq 1
        end

        it "scraped? should return true" do
          @root.scraped?.should be_true
        end
      end

      context "when robots.txt disallows /secret and we have anchor to it on start page" do
        before(:each) do
          @options.use_robots = true
          Typhoeus.stub(@start_url.to_s).and_return(Typhoeus::Response.new(body: "<html><a href=\"/secret\"></a></html>", code: 200, headers: { "Content-Type" => "text/html"}))
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_disallow_secret], code: 200))
          @root = @core.start(@host, @start_url).first
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

      context "when robots.txt allows everything and we have anchor on start page" do
        before(:each) do
          @options.use_robots = true
          Typhoeus.stub(@start_url.to_s).and_return(Typhoeus::Response.new(body: "<html><a href=\"/secret\"></a></html>", code: 200, headers: { "Content-Type" => "text/html"}))
          Typhoeus.stub(UrlHelper::get_normalized_url(@host, "/secret").to_s).and_return(Typhoeus::Response.new(body: "<html></html>", code: 200, headers: { "Content-Type" => "text/html"}))
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_allow_all], code: 200))
          @root = @core.start(@host, @start_url).first
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

      context "when robots.txt is ignored and we have anchor on start page" do
        before(:each) do
          @options.use_robots = false
          Typhoeus.stub(@start_url.to_s).and_return(Typhoeus::Response.new(body: "<html><a href=\"/secret\"></a></html>", code: 200, headers: { "Content-Type" => "text/html"}))
          Typhoeus.stub(UrlHelper::get_normalized_url(@host, "/secret").to_s).and_return(Typhoeus::Response.new(body: "<html></html>", code: 200, headers: { "Content-Type" => "text/html"}))
          @root = @core.start(@host, @start_url).first
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
        @core = Core.new(@out, @options)
      end

      context "when called with traversal depth of 1" do
        before(:each) do
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_allow_all], code: 200))
          @html_fixtures["d1_html_fixtures"].each do |url, html|
            url = UrlHelper::get_normalized_url(@host, url.to_s.tr("\"", ""))
            Typhoeus.stub(url.to_s).and_return(Typhoeus::Response.new(body: html, code: 200, headers: { "Content-Type" => "text/html"}))
          end
          Typhoeus.stub(/\/\/www.nisdom.com/).and_return(Typhoeus::Response.new(body: "something", code: 200, headers: { "Content-Type" => "text/html"}))
          @options.use_robots = true
          @options.max_page_depth = 1
          @root = @core.start(@host, @start_url).first
        end

        it "should return 6 pages" do
          @root.count.should eq 6
        end

        it "scraped? should be true for the root page" do
          @root.scraped?.should be_true
        end

        it "depth_reached? should be true for the 1. child page" do
          @root.sub_pages[0].depth_reached?.should be_true
        end

        it "depth_reached? should be true for the 2. child page" do
          @root.sub_pages[1].depth_reached?.should be_true
        end

        it "external_domain? should be true for the 3. child page" do
          @root.sub_pages[2].external_domain?.should be_true
        end

        it "depth_reached? should be true for the 4. child page" do
          @root.sub_pages[3].depth_reached?.should be_true
        end

        it "external_domain? should be true for the 5. child page" do
          @root.sub_pages[4].external_domain?.should be_true
        end
      end

      context "when called with traversal depth of 4" do
        before(:each) do
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_allow_all], code: 200))
          @html_fixtures["d4_html_fixtures"].each do |url, html|
            url = UrlHelper::get_normalized_url(@host, url.to_s.tr("\"", ""))
            Typhoeus.stub(url.to_s).and_return(Typhoeus::Response.new(body: html, code: 200, headers: { "Content-Type" => "text/html"}))
          end
          Typhoeus.stub(/\/\/www.nisdom.com/).and_return(Typhoeus::Response.new(body: "something", code: 200, headers: { "Content-Type" => "text/html"}))
          @options.use_robots = true
          @options.max_page_depth = 4
          @root = @core.start(@host, @start_url).first
        end

        it "count should return 41 pages starting from root page" do
          @root.count.should eq 41
        end

        it "scraped? should return true for the root page" do
          @root.scraped?.should be_true
        end

        it "scraped? should return true for the first child page" do
          @root.sub_pages[0].scraped?.should be_true
        end

        it "count should return 26 pages starting from the first child page" do
          @root.sub_pages[0].count.should eq 26
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

      context "when called with traversal depth of 4 and using robots.txt that blocks http://www.nisdom.com/tag" do
        before(:each) do
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_disallow_tag], code: 200))
          @html_fixtures["d4_html_fixtures"].each do |url, html|
            url = UrlHelper::get_normalized_url(@host, url.to_s.tr("\"", ""))
            Typhoeus.stub(url.to_s).and_return(Typhoeus::Response.new(body: html, code: 200, headers: { "Content-Type" => "text/html"}))
          end
          Typhoeus.stub(/\/\/www.nisdom.com/).and_return(Typhoeus::Response.new(body: "something", code: 200, headers: { "Content-Type" => "text/html"}))
          @options.use_robots = true
          @options.max_page_depth = 4
          @root = @core.start(@host, @start_url).first
        end

        it "count should return 31 pages starting from root page" do
          @root.count.should eq 31
        end

        it "scraped? should return true for the root page" do
          @root.scraped?.should be_true
        end

        it "scraped? should return true for the 1. child page" do
          @root.sub_pages[0].scraped?.should be_true
        end

        it "count should return 26 pages starting from the 1. child page" do
          @root.sub_pages[0].count.should eq 26
        end

        it "robots_forbidden? should return true for the 2. child page" do
          @root.sub_pages[1].robots_forbidden?.should be_true
        end

        it "external_domain? should return true for the 3. child page" do
          @root.sub_pages[2].external_domain?.should be_true
        end

        it "robots_forbidden? should return true for the 4. child page" do
          @root.sub_pages[3].robots_forbidden?.should be_true
        end

        it "external_domain? should return true for the 5. child page" do
          @root.sub_pages[4].external_domain?.should be_true
        end
      end

      context "when called with traversal depth of 4, using robots.txt that disallows /tag and all urls matching www.nisdom.com/category/c return 404" do
        before(:each) do
          Typhoeus.stub("http://www.nisdom.com/robots.txt").and_return(Typhoeus::Response.new(body: @robots[:robots_disallow_tag], code: 200))
          Typhoeus.stub(/\/category\/c/).and_return(Typhoeus::Response.new(body: "something", code: 404, headers: {"Content-Type" => "text/html"}))
          @html_fixtures["d4_html_fixtures"].each do |url, html|
            url = UrlHelper::get_normalized_url(@host, url.to_s.tr("\"", "")).to_s
            Typhoeus.stub(url.to_s).and_return(Typhoeus::Response.new(body: html, code: 200, headers: {"Content-Type" => "text/html"}))
          end
          Typhoeus.stub(/.*/).and_return(Typhoeus::Response.new(body: nil, code: 404, return_code: :operation_timedout, headers: nil))
          @options.use_robots = true
          @options.max_page_depth = 4
          @root = @core.start(@host, @start_url).first
        end

        it "count should return 12 pages starting from root page" do
          @root.count.should eq 12
        end

        it "scraped? should return true for the root page" do
          @root.scraped?.should be_true
        end

        it "scraped? should return true for the 1. child page" do
          @root.sub_pages[0].scraped?.should be_true
        end

        it "count should return 7 pages starting from the 1. child page" do
          @root.sub_pages[0].count.should eq 7
        end

        it "robots_forbidden? should return true for the 2. child page" do
          @root.sub_pages[1].robots_forbidden?.should be_true
        end

        it "external_domain? should return true for the 3. child page" do
          @root.sub_pages[2].external_domain?.should be_true
        end

        it "robots_forbidden? should return true for the 4. child page" do
          @root.sub_pages[3].robots_forbidden?.should be_true
        end

        it "external_domain? should return true for the 5. child page" do
          @root.sub_pages[4].external_domain?.should be_true
        end
      end
    end
  end
end
