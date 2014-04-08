require "spec_helper"
require_relative "../url_helper"

module SiteMapper
  describe UrlHelper do
    describe "get_normalized_host" do
      context "when called with invalid url" do
        it "should return nil value" do
          UrlHelper.get_normalized_host("http://www.digitaloce an.com").should be_nil
          UrlHelper.get_normalized_host("http://%/one/two").should be_nil
        end
      end

      context "when called with invalid url containing path" do
        it "should return nil value" do
          UrlHelper.get_normalized_host("http://www.nisdom.com/users").should be_nil
        end
      end

      context "when called with invalid url containing query string" do
        it "should return nil value" do
          UrlHelper.get_normalized_host("http://www.nisdom.com?query=123").should be_nil
        end
      end

      context "when called with an url containing the non-default port" do
        it "should return an url containing the non-defaut port" do
          UrlHelper.get_normalized_host("http://www.nisdom.com:8080/").to_s.should eq "http://www.nisdom.com:8080/"
        end
      end

      context "when called with an url missing the trailing slash" do
        it "should return a normalized version of the url" do
          UrlHelper.get_normalized_host("http://www.nisdom.com").to_s.should eq "http://www.nisdom.com/"
        end
      end
    end

    describe "get_normalized_uri" do
      context "when called with url starting with // (default protocol)" do
        it "should return uri including protocol" do
          UrlHelper.get_normalized_uri("http://www.nisdom.com", "//www.nisdom.com").to_s.should eq "http://www.nisdom.com/"
        end
      end

      context "when called with url starting with a single / (partial path starting from root)" do
        it "should return host concatenated with the given partial url" do
          UrlHelper.get_normalized_uri("http://www.nisdom.com/", "/resources/").to_s.should eq "http://www.nisdom.com/resources/"
          UrlHelper.get_normalized_uri("http://www.nisdom.com/", "/resources").to_s.should eq "http://www.nisdom.com/resources"
        end
      end

      context "when called with a partial path" do
        it "should return host concatenated with the given partial url" do
          UrlHelper.get_normalized_uri("http://www.nisdom.com/", "resources").to_s.should eq "http://www.nisdom.com/resources"
        end
      end

      context "when called with full path" do
        it "should return that same path" do
          UrlHelper.get_normalized_uri("http://www.nisdom.com", "http://www.nisdom.com").to_s.should eq "http://www.nisdom.com/"
          UrlHelper.get_normalized_uri("http://www.nisdom.com", "http://www.nisdom.com/resources").to_s.should eq "http://www.nisdom.com/resources"
        end
      end

      context "when path contains fragment" do
        it "should return path without fragment" do
          UrlHelper.get_normalized_uri("http://www.nisdom.com", "http://www.nisdom.com/#something").to_s.should eq "http://www.nisdom.com/"
        end
      end

      context "when path contains out of order parameters" do
        it "should return alphabetically sorted patameters" do
          UrlHelper.get_normalized_uri("http://www.nisdom.com", "http://www.nisdom.com/main?world=true&hello=1").to_s.should eq "http://www.nisdom.com/main?hello=1&world=true"
        end
      end
    end

    describe "is_uri_same_domain?" do
      context "when called with objects that don't act as URI" do
        let(:host) { "http://www.nisdom.com/" }
        let(:uri) { "http://www.nisdom.com" }

        it "should raise NoMethodError" do
          expect{ UrlHelper.is_uri_same_domain?(host, uri) }.to raise_error(NoMethodError)
        end
      end

      context "when called with URI objects of the same domain" do
        let(:host) { Addressable::URI.parse("http://www.nisdom.com/").normalize }
        let(:uri) { Addressable::URI.parse("http://www.nisdom.com").normalize }

        it "should return true" do
          UrlHelper.is_uri_same_domain?(host, uri).should be true
        end
      end
    end
  end
end