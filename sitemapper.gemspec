require_relative "lib/sitemapper/version"

Gem::Specification.new do |spec|
  spec.name          = "sitemapper"
  spec.version       = Sitemapper::VERSION
  spec.authors       = ["Orest Kulik"]
  spec.email         = ["orest@nisdom.com"]

  spec.summary       = %q{Sitemapper is a simple, static web pages hierarchy explorer.}
  spec.description   = %q{It starts from the arbitrary page you provide and descents into the tree of links until it either traverses all possible content on site or stops at some predefined traversal depth. It is written in Ruby and implemented as a command line interface (CLI) application. Based on user preference, it can output text reports in a standard sitemap.xml form (used by many search engines), a dot file (for easier site hierarchy visualization, [graphviz][graphviz] compatible), a plain text file (displaying detailed hierarchical relations between pages) and a simple html format.}
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["source_code_uri"] = "https://github.com/okulik/sitemapper"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("typhoeus", "~> 0.6", ">= 0.6.8")
  spec.add_runtime_dependency("nokogiri", "~> 1.6", ">= 1.6.1")
  spec.add_runtime_dependency("webrobots", "~> 0.1", ">= 0.1.1")
  spec.add_runtime_dependency("addressable", "~> 2.3", ">= 2.3.6")
  spec.add_runtime_dependency("public_suffix", "~> 1.4", ">= 1.4.2")
  spec.add_runtime_dependency("digest-murmurhash", "~> 0.3", ">= 0.3.0")
  spec.add_runtime_dependency("graphviz", "~> 0.4", ">= 0.4.0")
  spec.add_runtime_dependency("activesupport", "~> 6.0", ">= 6.0.3.2")

  spec.add_development_dependency("pry")
  spec.add_development_dependency("pry-doc")
  spec.add_development_dependency("pry-byebug")
end
