module SiteMapper
  class Page
    attr_reader :path
    attr_reader :sub_pages
    attr_reader :images
    attr_reader :links
    attr_reader :scripts

    INDENT = ' '

    def initialize(path)
      @path = path
      @sub_pages = []
      @images = []
      @links = []
      @scripts = []
    end

    def to_s
      out = []
      dump(self, out)
      return out.join('')
    end

    def count
      tree_count(self)
    end

    private

    def tree_count(page)
      counter = 0
      if page.is_a?(Page)
        counter += 1
        page.sub_pages.each do |sub|
          counter += tree_count(sub)
        end
      end
      return counter
    end

    def dump(page, out, depth=0)
      indent = INDENT*2*depth
      if page.is_a?(Page)
        out << "#{indent}page(#{depth}*): #{page.path}\n"
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
            dump(sub_page, out, depth + 1)
          end
        end
      else
        out << "#{indent}page(#{depth}): #{page}\n"
      end
    end
  end
end
