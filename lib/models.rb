class Initializer < Struct.new(:resource)

  ROOT = '/templates/%s'

  def self.call(resource)
    new(resource).run
  end

  def touch(basename)
    resource.join(basename).put StringIO.new
  end
  def copy_file(source, basename)
    resource.join(source).copy resource.join(basename)
  end
  def copy_files(index, *paths)
    copy_file ROOT % "#{ index }.html", 'index.html'
    paths.each { |path| copy_file ROOT % path, File.basename(path) }
  end

  def run
    raise NoMethodError
  end

end

require "#{ File.dirname __FILE__ }/models/page"
require "#{ File.dirname __FILE__ }/models/navigation"
