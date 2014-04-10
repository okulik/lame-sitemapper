# SiteMapper

SiteMapper is a simple web crawler that can produce information about a domain and pages it visits. It can produce reports in many interesting formats like sitemap.xml, dot (graphviz compatible), text or html.

See [http://github.com/okulik/sitemapper/][github-sitemapper] for more information.

## Features
* Obeys robots.txt (optional).
* Produces 4 different types of report i.e. 'text', 'sitemap', 'html', 'graph' and 'test_yml'.
* Tracks HTTP redirects.
* Possibility to choose number of concurrent threads.

## Installation
Go to download folder and run from console (make sure you have [bunder][bundler]):  
`bundler install`

## Requirements
* typhoeus
* nokogiri
* webrobots
* addressable
* public_suffix
* digest-murmurhash
* graphviz
* pry
* pry-doc
* pry-debugger
* rspec

## Examples
crawl up to depth 3 of page links, use 6 threads, disregard robots.txt and create a hierarchical text report  
`ruby site_mapper.rb "http://www.some.site.mom" -l 0 -d 3 -t 6 --no-robots`

crawl up to depth 4, use 6 threads, disregard robots.txt, create dot file, convert it to png file and open it (you need to have installed [graphviz][graphviz])  
`ruby site_mapper.rb "http://www.some.site.mom" -l 0 -d 4 -t 6 --no-robots -r graph > site.dot && dot -Tpng site.dot > site.png && open site.png`

traverse up to level 2, obey robots.txt and create an html report  
`ruby site_mapper.rb "http://www.some.site.mom" -d 2 -r html > site.html && open site.html`

[graphviz]: http://www.graphviz.org/
[github-sitemapper]: http://github.com/okulik/sitemapper/
[bundler]: http://bundler.io/