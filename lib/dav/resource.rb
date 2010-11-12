module Dav
  class Resource
    require "#{ File.dirname __FILE__ }/http_status"
    include Dav::HTTPStatus
    attr_reader :path

    def initialize(path, request)
      @path = Pathname path
      @request = request
    end

    def find_resources
      case @request.env['HTTP_DEPTH']
      when '0'
        [self]
      when '1'
        [self] + @path.children
      else
        [self] + descendants
      end
    end

    def get_properties(names)
      stats = Hash.new { |h, k| h[k] = [] }
      for name in names
        begin
          map_exceptions do
            stats[OK] << [name, (self.send(name) if self.respond_to?(name))]
          end
        rescue Status
          stats[$!] << name
        end
      end
      stats
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

    def creationdate
      stat.ctime
    end
    def displayname
      'test'
    end
    def getlastmodified
      stat.mtime
    end
    def getetag
      sprintf('%x-%x-%x', stat.ino, stat.size, stat.mtime.to_i)
    end
    def resourcetype
      Nokogiri::XML::fragment('<collection/>') if @path.directory?
    end
    def getcontenttype
      'test'
    end
    def getcontentlength
      stat.size
    end

    def stat
      @stat ||= File.stat(@path)
    end
  
    def descendants(children = nil)
      return [] unless @path.directory?
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