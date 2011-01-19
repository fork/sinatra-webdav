module DAV
  module FileBackend
    Sendfile = Class.new(File) { alias to_path path }

    module ClassMethods
      attr_accessor :root
    end

    def self.included(base)
      base.extend ClassMethods
      base.root = Dir.getwd
    end

    def open(mode = nil)
      unless block_given?
        Sendfile.open(path, mode || 'r')
      else
        Sendfile.open(path, mode || 'r') { |io| yield io }
      end
    end

    def self.supports?(method)
      %w[ exist? open ].include? method.to_s
    end

    def path
      File.join "#{ resource.root }#{ URI.unescape uri.path }".split('/')
    end

    def collection?
      File.directory? path
    end
    def exist?
      File.exist? path
    end
    def children
      collection = []
      return collection unless collection?

      Dir.open path do |dir|
        while name = dir.read
          next if name == '.' or name == '..'

          name << '/' if File.directory? File.join(path, name)

          instance = join name
          yield instance if block_given?
          collection << instance
        end
      end

      collection
    end
    def properties=(props)
      FileUtils.copy props.path, properties.path if File.exist?(props.path)
    end
    def properties
      DAV::Properties::XML self
    end

    def mkcol
      Dir.mkdir path
    end
    def delete(header)
      if collection?
        Dir.unlink path
      else
        File.unlink path
      end
      properties.delete
    end

  end
end
