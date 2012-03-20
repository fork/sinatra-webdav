require 'pathname'
require 'tmpdir'

# TODO use chambermaid for a typed implementation

module DAV
  class FileStorage < Storage
    include Addressable

    attr_accessor :memory

    def initialize(opts = {})
      # default to a tmpdir, so we do not accidentially overwrite/delete data
      path = opts.fetch :root, Dir.tmpdir
      path = File.join path, opts[:prefix] || File.basename(__FILE__)

      @opts   = opts
      @memory = Pathname File.expand_path(path)

      @memory.mkpath unless @memory.exist?

      unless @memory.directory? or @memory.writable?
        raise "Cannot store data at #{ @memory }"
      end
    end

    def scope(opts)
      self.class.new @opts.merge(opts)
    end

    def get(key)
      path = reader key
      path.read if path.file?
    end
    def set(key, value)
      path = reader key
      path.rmtree if path.exist?

      path.dirname.mkpath

      if value.nil?
        path.mkpath
      else
        path.open('w') { |file| file << value }
      end

      value
    end
    def delete(key)
      path = reader key
      content = path.file?? path.read : nil
      path.rmtree
    ensure
      return content
    end

    def member?(key)
      reader(key).exist?
    end

    def keys(pattern = nil)
      paths = []
      @memory.find do |path|
        Find.prune if pattern and not path.fnmatch? pattern
        paths << path.relative_path_from(@memory).to_s
      end
      paths
    end

    def pathname(key)
      basenames = key.split '/'
      basenames.shift if basenames.first and basenames.first.empty?

      @memory.join File.join(basenames)
    end
    alias reader pathname

  end
end
