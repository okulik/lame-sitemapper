# SiteMapper

SiteMapper is a simple, static web pages hierarchy explorer. It starts from the arbitrary page you provide and descents into the tree of links until it either traverses all possible content on site or some predefined traversal depth. It is written in Ruby and implemented as a command line interface (CLI) application. Based on user preference, it can output text reports in a standard sitemap.xml form (used by many search engines), a dot file (for easier site hierarchy visualization, [graphviz][graphviz] compatible), a plain text file (displaying detailed hierarchical relations between pages) or a simple html format.

The main challenge in web site links traversal is to know if some link has been previously seen and, accordingly, not to explore any further in that direction. This prevents infinite traversal of pages, jumping from link to link forever.

See [http://www.nisdom.com/a-simple-ruby-sitemap-xml-generator/][nisdom-sitemapper] for more details.

## Features
* Obeys robots.txt (can be optionally disregarded).
* Produces 4 different types of report i.e. 'text', 'sitemap', 'html', 'graph' and 'test_yml'.
* Tracks HTTP redirects.
* Possibility to choose the number of concurrent threads.

## Installation
Go to download folder and run from console (make sure you have [bundler][bundler]): 
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

[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/080d96b2c1703beb76b392c4856b3760 "githalytics.com")](http://githalytics.com/okulik/sitemapper)

[graphviz]: http://www.graphviz.org/
[github-sitemapper]: http://github.com/okulik/sitemapper/
[bundler]: http://bundler.io/
[nisdom-sitemapper]: http://www.nisdom.com/a-simple-ruby-sitemap-xml-generator/