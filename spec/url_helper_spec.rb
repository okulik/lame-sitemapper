# frozen_string_literal: true

require "spec_helper"

describe LameSitemapper::UrlHelper do
  describe "get_normalized_host" do
    context "when called with a space in host name" do
      it "returns nil value" do
        described_class.get_normalized_host("http://www.nis dom.com").should be_nil
      end
    end

    context "when called with a missing host" do
      it "returns nil value" do
        described_class.get_normalized_host("http://%/one/two").should be_nil
      end
    end

    context "when called with an invalid tld" do
      it "returns nil value" do
        described_class.get_normalized_host("http://www.nisdom.wrong").should be_nil
      end
    end

    context "when called with url string containing path, query string and fragment" do
      it "returns Addressable::URI object" do
        described_class.get_normalized_host("http://www.nisdom.com/users?red_dwarf#details").is_a?(Addressable::URI)
      end
      
      it "returns url without path" do
        described_class.get_normalized_host("http://www.nisdom.com/users?red_dwarf#details").to_s.should eq "http://www.nisdom.com/"
      end
    end

    context "when called with a valid instance of Addressable::URI object" do
      it "returns Addressable::URI object" do
        described_class.get_normalized_host(Addressable::URI.parse("http://www.nisdom.com/users?red_dwarf#details")).to_s.should eq "http://www.nisdom.com/"
      end
    end

    context "when called with an url containing the non-default port" do
      it "returns an url containing the non-defaut port" do
        described_class.get_normalized_host("http://www.nisdom.com:8080/").to_s.should eq "http://www.nisdom.com:8080/"
      end
    end

    context "when called with an url missing the trailing slash" do
      it "returns an url with a trailing slash" do
        described_class.get_normalized_host("http://www.nisdom.com").to_s.should eq "http://www.nisdom.com/"
      end
    end
  end

  describe "get_normalized_url" do
    let(:host) { described_class.get_normalized_host("https://www.nisdom.com:8080") }

    context "when called with url starting with // (default protocol)" do
      it "returns url including host's protocol" do
        described_class.get_normalized_url(host, "//www.nisdom.com").to_s.should eq "https://www.nisdom.com/"
      end
    end

    context "when called with url starting with a single / (partial path starting from root)" do
      it "returns protocol and host concatenated with the given partial url" do
        described_class.get_normalized_url(host, "/resources/").to_s.should eq "https://www.nisdom.com:8080/resources/"
        described_class.get_normalized_url(host, "/resources").to_s.should eq "https://www.nisdom.com:8080/resources"
      end
    end

    context "when called with an invalid tld" do
      it "returns nil value" do
        described_class.get_normalized_url(host, "http://www.nisdom.wrong").should be_nil
      end
    end

    context "when called with only a path or query" do
      it "returns protocol, host and port with the given path or query" do
        described_class.get_normalized_url(host, "resources").to_s.should eq "https://www.nisdom.com:8080/resources"
      end

      it "returns protocol, host and port with the given path or query" do
        described_class.get_normalized_url(host, "?a=b").to_s.should eq "https://www.nisdom.com:8080/?a=b"
      end
    end

    context "when called with the full url" do
      it "returns that same url" do
        described_class.get_normalized_url(host, "http://www.nisdom.com").to_s.should eq "http://www.nisdom.com/"
        described_class.get_normalized_url(host, "http://www.nisdom.com/resources").to_s.should eq "http://www.nisdom.com/resources"
      end
    end

    context "when url contains fragment" do
      it "returns url without fragment" do
        described_class.get_normalized_url("http://www.nisdom.com", "http://www.nisdom.com/#something").to_s.should eq "http://www.nisdom.com/"
      end
    end

    context "when url contains out of order parameters" do
      it "returns url with alphabetically sorted patameters" do
        described_class.get_normalized_url("http://www.nisdom.com", "http://www.nisdom.com/main?world=true&hello=1").to_s.should eq "http://www.nisdom.com/main?hello=1&world=true"
      end
    end
  end

  describe "is_url_same_domain?" do
    context "when called with URI objects from the same domain" do
      let(:host) { described_class.get_normalized_host("https://www.nisdom.com:8080") }
      let(:url) { described_class.get_normalized_url(host, "http://www.nisdom.com/users?red_dwarf") }

      it "returns true" do
        expect(described_class.is_url_same_domain?(host, url)).to eq(true)
      end
    end

    context "when called with URI objects from differend sub domains" do
      let(:host) { described_class.get_normalized_host("https://www.nisdom.com:8080") }
      let(:url) { described_class.get_normalized_url(host, "http://blog.nisdom.com/users?red_dwarf") }

      it "returns false" do
        expect(described_class.is_url_same_domain?(host, url)).to eq(false)
      end
    end
  end
end
