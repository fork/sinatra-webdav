module DAV
  class Properties < Struct.new(:resource_id, :document)
    extend PropertyAccessors
    include DAV

    BLANK = <<-XML
<?xml version="1.0" encoding="utf-8" ?>
<D:prop xmlns:D="DAV:">
  <D:creationdate/>
  <D:displayname/>
  <D:getcontentlanguage/>
  <D:getcontentlength/>
  <D:getcontenttype/>
  <D:getetag/>
  <D:getlastmodified/>
  <D:lockdiscovery/>
  <D:resourcetype/>
  <D:supportedlock/>
  <D:getlastmodified/>
</D:prop>
XML
    ALLPROP = <<-XML
<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>
XML

    # list of protected properties grouped by namespace href
    PROTECTED = Hash.new { |mem, ns| mem[ns] = [] }
    PROTECTED['DAV:'] = %w[
      displayname
      getcontentlanguage
      getcontentlength
      getcontenttype
      getetag
      getlastmodified
      lockdiscovery
      resourcetype
      supportedlock
    ]

    # raises when patch tries to modify a protected property
    class PropertyProtected < DAV::Error
      def initialize
        super 'cannot-modify-protected-property'
      end
    end
    class NullNamespace < DAV::Error
      def initialize
        super ''
      end
    end

    property :creation_date => :creationdate,
             :last_modified => :getlastmodified do

      reader { |node| str = node.content; str.empty?? nil : Time.parse(str) }
      writer { |node, time| node.content = time.httpdate }
    end

    property :display_name     => :displayname,
             :content_language => :getcontentlanguage,
             :content_type     => :getcontenttype,
             :entity_tag       => :getetag

    property :content_length => :getcontentlength do
      reader { |node| Integer node.content }
      writer { |node, value| node.content = value }
    end

    property :lock_discovery => :lockdiscovery do
      #reader {|*|}
      #writer {|*|}
    end

    property :resource_type => :resourcetype do
      reader do |node|
        node.css('*').map { |n| n.name }.join unless node.children.empty?
      end
      writer do |node, value|
        node.children.remove
        node.add_child node.document.create_element(value) unless value.nil?
      end
    end

    property :supported_lock => :supportedlock do
      #reader {|*|}
      #writer {|*|}
    end

    def initialize(resource)
      data     = property_storage.get(resource.id) || BLANK
      document = Nokogiri::XML data

      super resource.id, document
    end

    # Renders the document.
    def to_xml
      document.root.to_xml
    end

    # Copies the document to destinated properties objects.
    def copy(destination)
      destination.document = document.clone
    end

    def patch(request, response)
      request.rewind
      request = Nokogiri::XML request.read

      properties = []
      protected_properties = []

      response.precondition do |condition|
        condition.unprocessable_entity! unless root = request.root

        root.elements.each do |modifier|
          condition.conflict! if modifier.name !~ /(?:set|remove)/

          method_name = modifier.name
          modifier.css('D|prop > *', 'D' => 'DAV:').each do |property|
            unless protected? property
              properties << [ method_name, property ]
            else
              protected_properties << property
            end
          end

          protected_properties.empty? or
          condition.forbidden! 'cannot-modify-protected-property'
        end
      end

      response.property_status do |status|

        if response.precondition.ok?
          properties.each do |(modifier, prop)|
            send modifier, prop
            status.properties[200] << prop
          end
        else
          status.properties[403] = protected_properties.
          each { |prop| prop.children.remove }
          status.properties[424] = properties.values.flatten.
          each { |prop| prop.children.remove }
        end
      end

      response.postcondition do |status|
        # TODO http://tools.ietf.org/html/rfc3253#section-3.12
      end

      self
    end

    def find(request, response)
      request.rewind
      xml = request.read
      xml = ALLPROP if xml.empty? # default: leg - wait for it - acy
      request = Nokogiri::XML xml

      nodes = document.root.elements
      nodes.each { |n| nodes << nodes.delete(n).clone } # clone warz

      response.property_status do |status|
        request.root.css('D|prop, D|propname, D|allprop', 'D' => 'DAV:').
        each do |selector|
          case selector.name
          when 'prop'
            selector.elements.each do |e|
              node = (namespace = e.namespace) ?
                nodes.at("./self::P:#{ e.name }", 'P' => namespace.href) :
                nodes.at("./self::#{ e.name }")

              if node
                status.properties[200] << node
              else
                status.properties[404] << e
              end
            end
          when 'propname'
            # wtf: NodeSet#each does return INT!
            nodes.each { |n| n.children.remove }
            status.properties[200] = nodes
          when 'allprop'
            status.properties[200] = nodes
          end
        end
      end

      self
    end

    # Compares another Properties object using the resource IDs.
    def ==(other)
      Properties === other and resource_id == other.resource_id
    end

    # Calls block for each property in all namespaces.
    def each
      if block_given?
        document.root.elements.each do |node|
          yield node.name, node.content
        end
      else
        Enumerator.new self, :each
      end
    end

    # Resource isn't a collection if its resourcetype property is self-closed.
    # Therefor the property value must be nil.
    def collection?
      not resource_type.nil?
    end

    # Stores the current xml presentation in the storage
    def store
      property_storage.set resource_id, to_xml
    end
    def delete
      property_storage.delete resource_id
    end

    protected

      def protected?(prop)
        if namespace = prop.namespace
          PROTECTED[namespace.href].include? prop.name
        end
      end
      def protect!(prop)
        raise PropertyProtected if protected?
      end

      def find_node(property, name = property.name, ns = property.namespace)
        if ns
          document.root.at_xpath "C:#{ name }", 'C' => ns.href
        else
          document.root.at_xpath name
        end
      end

      def set(property)
        node = find_node property
        node ||= document.root.add_child document.create_element(property.name)

        href = property.namespace.href if property.namespace

        property.namespace_scopes.each do |ns|
          ns = node.add_namespace_definition ns.prefix, ns.href
          node.namespace = ns if ns.href == href
        end
        node.children = property.children

        node
      end
      def remove(property)
        node = find_node property
        node.remove if node

        node
      end

      def fetch(node_name, default = nil)
        node = document.xpath("/D:prop/D:#{ node_name }", 'D' => 'DAV:').first || default
        block_given?? yield(node) : node if node
      end
      def add_property(node_name)
        node = document.create_element("#{ node_name }", 'xmlns:D' => 'DAV')
        document.root.add_child node
        node.namespace = document.root.namespace
        node
      end

  end
end
