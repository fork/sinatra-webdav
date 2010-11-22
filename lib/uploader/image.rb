module Uploader
  class Image < Uploader::Base
    include CarrierWave::MiniMagick

    # use processing like
    # process :resize_to_fill => [200, 200]
  end
end