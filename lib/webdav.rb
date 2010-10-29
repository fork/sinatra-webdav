Bundler.require
require "#{ File.dirname __FILE__ }/sinatra/templates/slim"

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

  # For the time being we use the DAV 1 compliance class until we support
  # the LOCK methods.
  #
  # Add methods in the 'Allow' header when we support them.
  #
  # see http://www.webdav.org/specs/rfc4918.html#rfc.section.18
  OPTIONS_HEADER = { 'DAV' => '1', 'Allow' => 'OPTIONS, HEAD, GET, MKCOL, PUT, DELETE, COPY' }

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

  route 'MKCOL', '/*' do
    path = File.join options.public, params[:splat][0]

    forbidden if path.include? STAR
    conflict unless File.exists? File.dirname(path)
    not_allowed if File.exists? File.expand_path(path)
    unsupported if request.body.size > 0

    Dir.mkdir path

    ok
  end

  route 'COPY', '/*' do
    source = File.join options.public, params[:splat][0]
    dest = File.join options.public, URI.parse(request.env['HTTP_DESTINATION']).path

    Dir.mkdir dest if File.directory?(source) and not File.exist?(dest)

    FileUtils.cp_r source, dest
    
    ok
  end

  put '/*' do
    path = File.join options.public, params[:splat][0]
    conflict unless File.exists? File.dirname(path)

    write request.body, path

    created
  end

  delete '/*' do
    path = File.join options.public, params[:splat][0]

    not_found unless File.exists? path
    FileUtils.rmtree path

    ok
  end

  get '/*' do
    root = options.public
    glob = make_glob params[:splat].first, root

    forbidden if glob.include? STARS
    not_found unless glob.include? STAR or File.exists? glob

    list = Dir[glob].map! { |path| file_values path, root }
    path = glob[root.length..-1]

    slim :index, :locals => {
      :title => "/#{ path }",
      :list => list
    }
  end

  def make_glob(path, root)
    path   += SPACE
    dirname = File.dirname path
    pattern = File.basename path
    pattern.strip!
    pattern = STAR if pattern.empty?

    File.join root, dirname, pattern
  end
  def file_values(path, root)
    stat  = File.stat path
    path  = path[root.length..-1]
    name  = File.basename path
    mtime = stat.mtime

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
  def created
    halt 201
  end
  def forbidden
    error 403
  end
  def not_allowed
    error 405
  end
  def conflict
    error 409
  end
  def unsupported
    error 415
  end

  def write(io, path)
    tempfile = "#{ path }.#{ Process.pid }.#{ Thread.current.object_id }"

    open(tempfile, 'wb') do |file|
      while part = io.read(8192)
        file << part
      end
    end

    File.rename(tempfile, path)
  ensure
    File.unlink(tempfile) rescue nil
  end

end
