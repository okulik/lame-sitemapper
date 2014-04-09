require "graphviz"
require_relative "page"

module SiteMapper
  class ReportGenerator
    INDENT = " "
    XML_PROLOG = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
EOS
    XML_EPILOG = "</urlset>"
    XML_NODE_TEMPLATE1 = <<-EOS
<url>
  <loc>%s</loc>
</url>
EOS
    XML_NODE_TEMPLATE2 = <<-EOS
<url>
  <loc>%s</loc>
  <changefreq>%s</changefreq>
</url>
EOS
    HTML_PROLOG = <<-EOS
<html>
  <head>
    <title>%s sitemap</title>
  </head>
  <body>
    <h1>Site %s</h1>
EOS
    HTML_EPILOG = <<-EOS
</body>
</html>
EOS

    def initialize options, host
      @options = options
      @host = host
    end

    def to_text(page)
      out = ""
      tree_to_text(page, out)
      return out
    end

    def to_sitemap(page)
      out = XML_PROLOG
      page.each do |p|
        if @options.frequency_type != :none
          out << XML_NODE_TEMPLATE2 % [ p.path, @options.frequency_type ]
        else
          out << XML_NODE_TEMPLATE1 % [ p.path ]
        end
      end
      out << XML_EPILOG
      return out
    end

    def to_html(page)
      out = HTML_PROLOG % [ page.path, page.path ]
      page.each do |p|
        out << "<h2>#{scraped_mark(p)}#{p.format_codes}<a href=\"#{p.path}\">#{p.path}</a></h2>\n"
        if p.scraped?
          out << "<h3>Images</h3>\n" if p.images.count > 0
          p.images.each do |img|
            uri = UrlHelper.get_normalized_url(@host, img)
            out << "<div>\n"
            out << "<a href=\"#{uri}\">#{uri}</a>\n"
            out << "</div>\n"
          end
          out << "<h3>Links</h3>\n" if p.links.count > 0
          p.links.each do |link|
            uri = UrlHelper.get_normalized_url(@host, link)
            out << "<div>\n"
            out << "<p>#{uri}</p>\n"
            out << "</div>\n"
          end
          out << "<h3>Scripts</h3>\n" if p.scripts.count > 0
          p.scripts.each do |script|
            uri = UrlHelper.get_normalized_url(@host, script)
            out << "<div>\n"
            out << "<p>#{uri}</p>\n"
            out << "</div>\n"
          end
        end
      end
      out << HTML_EPILOG
      return out
    end

    def to_graph(page)
      graph = Graphviz::Graph.new
      tree_to_graph(page, graph)
      return graph.to_dot
    end

    def to_test_yml(page)
      out = ""
      tree_to_test_yml(page, out)
      return out
    end

    private

    def tree_to_graph(page, node)
      n = node.add_node(page.path.to_s)
      unless page.scraped?
        n.attributes[:shape] = 'box' 
        n.attributes[:color] = (
          if page.robots_forbidden?
            'crimson'
          elsif page.depth_reached?
            'darkorange'
          elsif page.external_domain?
            'deeppink'
          elsif page.no_html?
            'blue'
          end
        )
      end
      page.sub_pages.each do |p|
        tree_to_graph(p, n)
      end
    end

    def tree_to_text(page, out, depth=0)
      indent = INDENT * 2 * depth
      if page.scraped?
        details = ": a(#{page.anchors.count}), img(#{page.images.count}), link(#{page.links.count}), script(#{page.scripts.count})"
      else
        details = ": #{page.format_codes}"
      end
      out << "#{indent}(#{depth})#{scraped_mark(page)}page #{page.path}#{details}\n"
      return unless page.scraped?

      if page.images.count > 0
        out << "#{indent}#{INDENT}images:\n"
        page.images.each { |img| out << "#{indent}#{INDENT*2}#{img}\n" }
      end
      if page.links.count > 0
        out << "#{indent}#{INDENT}links:\n"
        page.links.each { |link| out << "#{indent}#{INDENT*2}#{link}\n" }
      end
      if page.scripts.count > 0
        out << "#{indent}#{INDENT}scripts:\n"
        page.scripts.each { |script| out << "#{indent}#{INDENT*2}#{script}\n" }
      end
      if page.sub_pages.count > 0
        out << "#{indent}#{INDENT}pages:\n"
        page.sub_pages.each do |sub_page|
          tree_to_text(sub_page, out, depth + 1)
        end
      end
    end

    def tree_to_test_yml(page, out)
      if page.scraped?
        out << "\"#{page.path}\": \"\n"
        out << "<html>\n"
        page.sub_pages.each do |p|
          out << "  <a href=\\\"#{p.path}\\\"></a>\n"
        end
        out << "</html>\"\n"
        page.sub_pages.each do |p|
          tree_to_test_yml(p, out)
        end
      end
    end

    def scraped_mark(page)
      page.scraped? ? "* " : " "
    end
  end
end
