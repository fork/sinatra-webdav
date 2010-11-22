module Uploader
  autoload :Image, "#{ File.dirname __FILE__ }/uploader/image"

  # USAGE (e.g. for processing uploads)
  # u = Uploader::Image.new @public_path
  # u.process!
  
  class Base < CarrierWave::Uploader::Base
    storage :file

    def initialize(path)
      @path = path
    end

    def current_path
      @path
    end
  end
end