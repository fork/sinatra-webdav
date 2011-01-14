class Navigation

  def self.distribute(path)
    distribution = Distribution.build path
    distribution.apply Dir["#{ File.dirname path }/*/**/index.html"]
  rescue => e
    $stderr.puts 'OMFG!', e, '=' * 78, *e.backtrace
  end

  class Distribution < Struct.new(:top, :footer)
    TOP_SELECTOR    = '#header' # IDs should be unique, if not go fuck!
    FOOTER_SELECTOR = '#footer'

    OPTIONS = {
      :indent_text => '',
      :encoding    => 'UTF-8',
      :save_with   => Nokogiri::XML::Node::SaveOptions::AS_XHTML
    }


    def self.build(path)
      source = Nokogiri::XML File.read(path)

      top    = source.at_css(TOP_SELECTOR).inner_html
      footer = source.at_css(FOOTER_SELECTOR).inner_html

      new top, footer
    end

    def apply(paths)
      paths.each { |path| update path }
    end

    protected

      def write(path, content)
        # guard agaist the evils of unstrings
        raise TypeError unless content.respond_to? :to_s
        raise ArgumentError if content.to_s !~ /\S/m

        File.open(path, 'w') { |file| file.write content }
      end

      def update(path)
        html = File.read path
        page = Nokogiri::XML html

        page.encoding = 'UTF-8'
        page.css(TOP_SELECTOR).each { |node| node.inner_html = top }
        page.css(FOOTER_SELECTOR).each { |node| node.inner_html = footer }

        write path, page.to_xml(OPTIONS)
      rescue => e
        $stderr.puts 'Shit ...', e, *e.backtrace
        $stderr.puts '... happened while parsing ...', html
        $stderr.puts "... at #{ path }!"

        # restore old content
        write path, html
      end

  end

end
