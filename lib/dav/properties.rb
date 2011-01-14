module DAV
  class Properties < Struct.new(:document, :path, :resource)
    ROOT = File.join Dir.getwd, 'properties', 'group_files'
    
    def self.XML(resource)
      prop_path = File.join "#{ ROOT }#{ resource.uri.path }".split('/')
      
      doc = File.file?(prop_path) ? File.read(prop_path) : '<properties/>'
      new Nokogiri::XML(doc), prop_path, resource
    end

    def to_xml(xml, depth)
      prop = xml.at_css("propfind prop")

      construct = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |builder|
        builder.multistatus('xmlns' => "DAV:") do
          for r in find_resources(depth)
            builder.response do
              builder.href r.uri
              builder.propstat do
                builder.prop do
                  if prop
                    builder << r.properties.find(prop.element_children)
                  else
                    builder << r.properties.all
                  end
                end
              end
            end
          end
        end
      end

      construct.to_xml
    end

    def update(properties)
      build_properties_file!

      nodes = apply properties

      construct = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |builder|
        builder.multistatus('xmlns' => "DAV:") do
          builder.response do
            builder.href resource.uri
            builder.propstat do
              builder.prop do
                builder << nodes[:remove]
              end
            end
            builder.propstat do
              builder.prop do
                builder << nodes[:set]
              end
            end
          end
        end
      end

      File.open(path, 'w') {|f| f.write(document) }
      construct.to_xml
    end

    def delete
      return unless File.exist?(path)
      if File.directory?(path)
        Dir.delete path if Pathname(path).children.empty?
      else
        File.delete path
      end
    end

    def find(props)
      result = []
      props.each do |p|
        name = p.node_name
        prop = find_with_namespace(xml_props, p)
        unless prop
          result << "<#{name}>#{send(name)}</#{name}>" if respond_to?(name)
        else
          result << prop.to_xml
        end
      end
      result << resourcetype
      result.join
    end

    protected

      def apply(xml)
        ns = xml.namespaces
        ns.delete 'xmlns'
        set, remove, selector = [], [], ''

        selector = "#{ns.keys.first.split(':').last}|" unless ns.empty?

        # has to be processed in order (set overwriting same prop etc...)
        xml.css("#{selector}propertyupdate > *").each do |child|
          prop = child.at_css("#{selector}prop > *")
          if child.node_name == 'set'
            result = set(prop)
            included = find_with_namespace(set, result)
            set.delete(included) if included
            set << result
          elsif child.node_name == 'remove'
            remove << remove(prop).to_xml
          end
        end

        { :set => set.map {|n| n.to_xml }.join, :remove => remove.join }
      end


      def set(node)
        found = find_with_namespace(xml_props, node)
        if found
          found.replace(node)
        else
          xml_props.empty?? document.root.add_child(node) : xml_props.after(node)
        end
      end
      def remove(node)
        found = find_with_namespace(xml_props, node)
        found.remove if found
        node
      end

      def collection?
        @collection ||= stat.directory?
      end
      def creationdate
        stat.ctime
      end
      def displayname
        File.basename resource.path
      end
      def getlastmodified
        stat.mtime.httpdate
      end
      def getetag
        sprintf('%x-%x-%x', stat.ino, stat.size, stat.mtime.to_i)
      end
      def resourcetype
        "<resourcetype>#{'<collection/>' if collection?}</resourcetype>"
      end
      def getcontenttype
        collection?? "text/html" : Rack::Mime.mime_type(File.extname(resource.path))
      end
      def getcontentlength
        stat.size
      end

      def stat
        @stat ||= File.stat resource.path
      end

      def default_properties
        %w[ creationdate
            displayname
            getlastmodified
            getetag
            resourcetype
            getcontenttype
            getcontentlength ]
      end

      def build_properties_file!
        return if File.exist? path

        FileUtils.mkpath File.dirname(path)
        xml = '<?xml version="1.0" encoding="utf-8"?><properties/>'
        File.open(path, 'w') {|f| f.write(xml) }
      end

      def find_with_namespace(node_array, node)
        node_array.find {|n|
          if n.namespace and node.namespace
            n.name == node.name and n.namespace.href == node.namespace.href
          else
            n.name == node.name
          end
        }
      end

      def find_resources(depth)
        case depth
        when 0
          [resource]
        when 1
          [resource] + resource.children
        else
          [resource] + resource.descendants
        end
      end

      def xml_props
        document.xpath('/properties/*')
      end

      def all
        default = default_properties.map {|p| "<#{p}>#{send(p)}</#{p}>"}.join
        xml_props.after(Nokogiri::XML::fragment(default)).to_xml unless xml_props.empty?
      end

  end
end