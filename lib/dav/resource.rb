load_path = File.expand_path '..', __FILE__
require "#{ load_path }/resource/children"
require "#{ load_path }/resource/convenience"
require "#{ load_path }/resource/actions"
require "#{ load_path }/resource/traversing"
require "#{ load_path }/base"

module DAV
  class Resource < DAV::Base
  end
end
