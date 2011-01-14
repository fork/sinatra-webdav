module Dav
  class Resource
    require "#{ File.dirname __FILE__ }/http_status"
    include DAV::HTTPStatus

    attr_reader :path, :public_path

    def initialize(path, request, options = {})
      @path = Pathname path
      @public_path = "/#{ @path.relative_path_from Pathname(options.public) }"
      @public_path << '/' if collection?
      @request = request
      @options = options
      @xml_props = []
      @xml_props_remove = []
    end

    def find_resources
      case @request.env['HTTP_DEPTH']
      when '0'
        [self]
      when '1'
        [self] + @path.children.map { |path| self.class.new path, @request, @options }
      else
        [self] + descendants
      end
    end

    def remove_properties(nodes)
       stats = Hash.new { |h, k| h[k] = [] }
       for node in nodes
         begin
           map_exceptions do
             stats[OK] << [node.name, remove_property(node)]
           end
         rescue Status
           stats[$!] << name
         end
       end
       prop_path.exist?? update_xml_props! : build_xml_props!
       stats
    end

    def set_properties(nodes)
       stats = Hash.new { |h, k| h[k] = [] }
       for node in nodes
         begin
           map_exceptions do
             stats[OK] << [node.name, set_property(node)]
           end
         rescue Status
           stats[$!] << name
         end
       end
       prop_path.exist?? update_xml_props! : build_xml_props!
       stats
    end

    def set_property(node)
      case node.name
      when 'resourcetype'    then self.resource_type = node.content
      when 'getcontenttype'  then self.content_type = node.content
      when 'getetag'         then self.etag = node.content
      when 'getlastmodified' then self.last_modified = Time.httpdate(node.content)
      else @xml_props << node; Nokogiri::XML.fragment(node.to_xml)
      end
    rescue ArgumentError
      raise HTTPStatus::Conflict
    end

    def remove_property(node)
      @xml_props_remove << node; Nokogiri::XML.fragment(node.to_xml)
    rescue ArgumentError
      raise HTTPStatus::Conflict
    end

    def build_xml_props!
      prop_builder do |xml|
        clean_props(@xml_props).each do |p|
          xml.prop do
            xml << p.to_xml
          end
        end
      end
      File.open(prop_path, 'w') {|f| f.write(prop_builder.to_xml) }
    end

    def clean_props(props)
      props.delete_if {|p| find_with_namespace(@xml_props_remove, p)}
    end

    def update_xml_props!
      xml = Nokogiri::XML File.read(prop_path)

      old_props = xml.css('properties prop').children
      old_props_array = old_props.to_a
      
      @xml_props.each do |p|
        node = find_with_namespace(old_props_array, p)
        if node
          old_props[old_props_array.index(node)].content = p.content
        else
          xml.at_css('properties') << "<prop>#{p.to_xml}</prop>"
        end
      end
      @xml_props_remove.each do |p|
        node = find_with_namespace(old_props_array, p)
        if node
          old_props[old_props_array.index(node)].remove
        end
      end

      File.open(prop_path, 'w') {|f| f.write(xml) }
    end

    def prop_path
      @prop_path ||= Pathname File.join(prop_dir, displayname)
    end

    def prop_dir
      prop_root = File.join @options.root, 'properties', @path.sub(@options.root, '')
      dir = collection?? prop_root : File.dirname(prop_root)
      @prop_dir ||= FileUtils.mkpath(dir).first
    end

    def prop_builder
      @prop_builder ||= Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
        xml.properties do
          yield xml if block_given?
        end
      end
    end

    def get_properties(names)
      stats = Hash.new { |h, k| h[k] = [] }
      for name in names
        begin
          map_exceptions do
            stats[OK] << [name.is_a?(String) ? name : name.node_name, get_property(name)]
          end
        rescue Status
          stats[$!] << name
        end
      end
      stats
    end

    def get_property(name_or_element)
      is_element = name_or_element.is_a?(Nokogiri::XML::Element)

      name = is_element ? name_or_element.node_name : name_or_element
      return send(name) if respond_to?(name)
      return unless prop_path.exist?
      
      xml = Nokogiri::XML File.read(prop_path)
      nodes = xml.css('properties prop').children
      node = find_with_namespace nodes.to_a, name_or_element

      return Nokogiri::XML.fragment(node.to_xml) if node
    end

    def property_names
      %w[ creationdate
          displayname
          getlastmodified
          getetag
          resourcetype
          getcontenttype
          getcontentlength ]
    end

    def collection?
      @collection ||= stat.directory?
    end
    def creationdate
      stat.ctime
    end
    def displayname
      File.basename(@path)
    end
    def getlastmodified
      stat.mtime.httpdate # %a, %d %b %Y %H:%M:%S GMT
    end
    def getetag
      sprintf('%x-%x-%x', stat.ino, stat.size, stat.mtime.to_i)
    end
    def resourcetype
      Nokogiri::XML::fragment('<resourcetype><collection/></resourcetype>') if collection?
    end
    def getcontenttype
      collection?? "text/html" : Rack::Mime.mime_type(File.extname(@path))
    end
    def getcontentlength
      stat.size
    end

    def stat
      @stat ||= File.stat(@path)
    end

    def find_with_namespace(set_array, node)
      set_array.find {|n|
        if n.namespace and node.namespace
          n.name == node.name and n.namespace.href == node.namespace.href
        else
          n.name == node.name
        end
      }
    end

    def descendants(children = nil)
      return [] unless collection?
      children ||= path_children
      children.each do |c|
        children << c
        children << descendants(c) if c.directory? 
      end
      children
    end

    def map_exceptions
      yield
    rescue
      case $!
      when URI::InvalidURIError then raise BadRequest
      when Errno::EACCES then raise Forbidden
      when Errno::ENOENT then raise Conflict
      when Errno::EEXIST then raise Conflict      
      when Errno::ENOSPC then raise InsufficientStorage
      else
        raise
      end
    end
  
  end
end