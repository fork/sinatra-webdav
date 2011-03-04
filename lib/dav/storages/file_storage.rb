require 'pathname'
require 'tmpdir'
require 'base64'

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

      # TODO Check if user can write, too.
      if @memory.exist? && !@memory.directory?
        raise "Cannot store data at #{ @memory }!"
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
      path.read.tap { |x| path.rmtree } if path.file?
    end

    def keys(pattern = nil)
      paths = []

      @memory.children.each do |scope|
        prefix = scope.basename

        # TODO use glob
        scope.children.each do |child|
          unless child.directory?
            key = "#{ prefix }#{ child.basename }"
            if not pattern or File.fnmatch? pattern, key
              paths << URI.unescape(key)
            end
          else
            # TODO recourse
          end
        end
      end

      paths
    end

    def pathname(key)
#      key = URI.encode_component key, URI::CharacterClasses::PATH

      basenames = key.split '/'
      basenames.shift if basenames.first and basenames.first.empty?

      @memory.join File.join(basenames)
    end
    alias reader pathname

  end
end
