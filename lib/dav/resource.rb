File.expand_path('..', __FILE__).tap do |load_path|
  require "#{ load_path }/resource/children"
  require "#{ load_path }/resource/convenience"
  require "#{ load_path }/resource/actions"
  require "#{ load_path }/resource/traversing"
  require "#{ load_path }/callbacks"
  require "#{ load_path }/base"
end

module DAV
  class Resource < DAV::Base
  end
end
