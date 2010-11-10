Bundler.require
require "#{ File.dirname __FILE__ }/sinatra/templates/slim"

# Sinatra based WebDAV implementation
#
# see http://www.webdav.org/specs/rfc4918.html
class WebDAV < ::Sinatra::Base
  set :root, File.expand_path('../..', __FILE__)
  disable :dump_errors, :static
  enable :raise_errors

  enable :sessions

  helpers do
    def protected!
      # TODO is return_to uri needed?
      
      # USE TO TEST WITH LITMUS (and comment out authorized stuff)
      #settings.set :public, File.join(settings.root, CUSTOM_PUBLIC)
      unauthorized unless authorized?
    end
    def authorized?
      not session[:user].nil?
    end
  end

  # testuser 'admin' 'whatever' / folder group_files/admins needed in root
  use OmniAuth::Builder do
    provider OmniAuth::Strategies::CAS, { :cas_server => 'https://cas.fork.de',
      :cas_service_validate_url => 'https://cas.fork.de/proxyValidate' }
  end

  get '/logout' do
    session[:user] = nil
    'logged out!'
  end

  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
    session[:user] = auth

    group_name = auth['extra']['group_name'].strip
    settings.set :public, File.join(settings.root, CUSTOM_PUBLIC, group_name)
    # TODO is return_to uri needed?
    redirect '/'
  end

  # We do not want to generate string all the time.
  SLASH = '/'
  SPACE = ' '
  STAR  = '*'
  STARS = '**'
  DASH  = '-'

  # name for custom public folder containing user group folders
  CUSTOM_PUBLIC = 'group_files'

  # Static type for directories.
  DIRECTORY_TYPE = 'directory'

  # For the time being we use the DAV 1 compliance class until we support
  # the LOCK methods.
  #
  # Add methods in the 'Allow' header when we support them.
  #
  # see http://www.webdav.org/specs/rfc4918.html#rfc.section.18
  OPTIONS_HEADER = { 'DAV' => '1', 
    'Allow' => 'OPTIONS, HEAD, GET, MKCOL, PUT, DELETE, COPY, MOVE, PROPFIND' }

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
    protected!
    path = File.join options.public, params[:splat][0]

    forbidden if path.include? STAR
    conflict unless File.exists? File.dirname(path)
    not_allowed if File.exists? File.expand_path(path)
    unsupported if request.body.size > 0

    Dir.mkdir path

    ok
  end

  route 'MOVE', '/*' do
    protected!
    source = File.join options.public, params[:splat][0]
    dest = File.join options.public, URI.parse(request.env['HTTP_DESTINATION']).path
    exists = File.exist? dest
    overwrite = request.env['HTTP_OVERWRITE'] == 'T'
    
    precondition_failed if not overwrite and exists
    not_allowed if not overwrite and exists and !File.directory?(dest)

    FileUtils.mv source, dest, :force => true

    exists ? no_content : created
  end

  route 'COPY', '/*' do
    protected!
    source = File.join options.public, params[:splat][0]
    dest = File.join options.public, URI.parse(request.env['HTTP_DESTINATION']).path
    exists = File.exist? dest

    precondition_failed if request.env['HTTP_OVERWRITE'] == 'F' and exists
    conflict unless File.exist?(File.dirname(dest))

    FileUtils.cp_r source, dest
    
    exists ? no_content : created
  end

  route 'PROPFIND', '/*' do
    xml = Nokogiri::XML request.body.read
    
    bad_request unless xml.errors.empty?

    #TODO xml response...
    ok
  end

  put '/*' do
    protected!
    putter = ::Put.new(params, options)
    if res = putter.process and res.first
      halt 201, no_cache_header, res.last
    elsif !res.first
      error 409 do
        res.last
      end
    end
  end

  delete '/*' do
    protected!
    path = File.join options.public, params[:splat][0]

    not_found unless File.exists? path
    FileUtils.rmtree path

    ok
  end

  get '/*' do
    protected!
    root = options.public
    glob = make_glob params[:splat].first, root

    forbidden if glob.include? STARS
    not_found unless glob.include? STAR or File.exists? glob
    return File.read(glob) if not glob.include? STAR and File.file? glob

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
  def no_content
    halt 204
  end
  def bad_request
    error 400
  end
  def unauthorized
    error 401
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
  def precondition_failed
    error 412
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

  def no_cache_header
    { 'Content-type' => 'text/plain; charset=UTF-8',
      'Expires' => 'Mon, 26 Jul 1997 05:00:00 GMT',
      'Last-Modified' => Time.now.strftime("%a, %d %b %Y %H:%M:%S GMT"), 
      'Cache-Control' => 'no-store, no-cache, must-revalidate',
      'Pragma' => 'no-cache' }
  end

end
