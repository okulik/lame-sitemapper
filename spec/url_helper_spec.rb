require 'spec_helper'
require_relative '../url_helper'

module SiteMapper
  describe UrlHelper do
    describe 'get_normalized_host' do
      context 'when called with invalid url' do
        it 'should return nil value' do
          UrlHelper.get_normalized_host('http://www.digitaloce an.com').should be_nil
          UrlHelper.get_normalized_host('http://%/one/two').should be_nil
        end
      end

      context 'when called with invalid url containing path' do
        it 'should return nil value' do
          UrlHelper.get_normalized_host('http://www.digitalocean.com/users').should be_nil
        end
      end

      context 'when called with invalid url containing query string' do
        it 'should return nil value' do
          UrlHelper.get_normalized_host('http://www.digitalocean.com?query=123').should be_nil
        end
      end

      context 'when called with an url containing the non-default port' do
        it 'should return an url containing the non-defaut port' do
          UrlHelper.get_normalized_host('http://www.digitalocean.com:8080/').to_s.should eq 'http://www.digitalocean.com:8080/'
        end
      end

      context 'when called with an url missing the trailing slash' do
        it 'should return a normalized version of the url' do
          UrlHelper.get_normalized_host('http://www.digitalocean.com').to_s.should eq 'http://www.digitalocean.com/'
        end
      end
    end

    describe 'get_normalized_uri' do
      context 'when called with url starting with // (default protocol)' do
        it 'should return uri including protocol' do
          UrlHelper.get_normalized_uri('http://digitalocean.com', '//digitalocean.com').to_s.should eq 'http://digitalocean.com/'
        end
      end

      context 'when called with url starting with a single / (partial path starting from root)' do
        it 'should return host concatenated with the given partial url' do
          UrlHelper.get_normalized_uri('http://digitalocean.com/', '/resources/').to_s.should eq 'http://digitalocean.com/resources/'
          UrlHelper.get_normalized_uri('http://digitalocean.com/', '/resources').to_s.should eq 'http://digitalocean.com/resources'
        end
      end

      context 'when called with a partial path' do
        it 'should return host concatenated with the given partial url' do
          UrlHelper.get_normalized_uri('http://digitalocean.com/', 'resources').to_s.should eq 'http://digitalocean.com/resources'
        end
      end

      context "when called with full path" do
        it "should return itself" do
          UrlHelper.get_normalized_uri('http://digitalocean.com', 'http://www.digitalocean.com').to_s.should eq 'http://www.digitalocean.com/'
          UrlHelper.get_normalized_uri('http://digitalocean.com', 'http://www.digitalocean.com/resources').to_s.should eq 'http://www.digitalocean.com/resources'
        end
      end
    end

    describe "is_uri_same_domain?" do
      context "when called with objects that don't act as URI" do
        let(:host) { 'http://digitalocean.com/' }
        let(:uri) { 'http://www.digitalocean.com' }

        it "should raise" do
          expect{ UrlHelper.is_uri_same_domain?(host, uri) }.to raise_error(NoMethodError)
        end
      end

      context "when called with URI objects of the same domain" do
        let(:host) { Addressable::URI.parse('http://digitalocean.com/').normalize }
        let(:uri) { Addressable::URI.parse('http://digitalocean.com').normalize }
        
        it "should return true" do
          UrlHelper.is_uri_same_domain?(host, uri).should be true
        end
      end
    end
  end
end