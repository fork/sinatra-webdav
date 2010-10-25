Bundler.require

# Sinatra based WebDAV implementation
#
# see http://www.webdav.org/specs/rfc4918.html
class WebDAV < ::Sinatra::Base
  set :root, File.expand_path('../..', __FILE__)
  disable :dump_errors
  enable :raise_errors

  # We do not want to generate string all the time.
  SLASH = '/'
  SPACE = ' '
  STAR  = '*'
  STARS = '**'
  DASH  = '-'

  # Static type for directories.
  DIRECTORY_TYPE = 'directory'

  # For the time being we use the Class 1 compliance class until we support
  # the LOCK methods.
  #
  # Add methods in the 'Allow' header when we support them.
  #
  # see http://www.webdav.org/specs/rfc4918.html#rfc.section.18
  OPTIONS_HEADER = { 'DAV' => '1', 'Allow' => 'OPTIONS, HEAD, GET, MKCOL' }

  route 'OPTIONS', '/*' do
    headers OPTIONS_HEADER
    ok
  end

  # Generic structure for a WebDAV method:
  # route 'METHOD', PATH do
  #   setup credentials
  #   check credentials
  #   do action
  #   response (ok, forbidden, ...)
  # end

  route 'MKCOL', '/*/' do
    path = File.join options.public, params[:splat][0]

    forbidden if path.include? STAR
    not_allowed if File.exists? path or not File.exists? File.dirname(path)

    Dir.mkdir path

    ok
  end

  get '/*' do
    glob = make_glob params[:splat].first

    forbidden if glob.include? STARS
    not_found unless glob.include? STAR or File.exists? glob

    list = Dir[glob].map! { |path| file_values path }

    haml :index, :locals => {
      :title => "/#{ glob }",
      :list => list
    }
  end

  def make_glob(path, root = options.public)
    path   += SPACE
    dirname = File.dirname path
    pattern = File.basename path
    pattern.strip!
    pattern = STAR if pattern.empty?

    File.join root, dirname, pattern
  end
  def file_values(path, root = options.public)
    stat  = File.stat path
    path  = path[root.length..-1]
    name  = File.basename path
    mtime = stat.mtime.httpdate

    unless stat.directory?
      size = stat.size
      type = Rack::Mime.mime_type File.extname(name)
    else
      path << SLASH
      path << STAR
      size = DASH
      type = DIRECTORY_TYPE
    end

    return path, name, size, type, mtime
  end

  def ok
    halt 200
  end
  def forbidden
    error 403
  end
  def not_allowed
    error 405
  end

end
