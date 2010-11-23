Bundler.require
require "#{ File.dirname __FILE__ }/sinatra/templates/slim"
require "#{ File.dirname __FILE__ }/dav/resource"
require "#{ File.dirname __FILE__ }/uploader"


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
      settings.set :public, File.join(settings.root, CUSTOM_PUBLIC)
      #unauthorized unless authorized?
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
    'Allow' => 'OPTIONS, HEAD, GET, MKCOL, PUT, DELETE, COPY, MOVE, PROPFIND, PROPPATCH' }

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
    protected!
    path = Pathname File.join(options.public, params[:splat][0])
    xml = Nokogiri::XML request.body.read
    
    bad_request unless xml.errors.empty?
    not_found unless path.exist?
    
    resource = Dav::Resource.new path, request, options

    if xml.at_css("propfind allprop")
      names = resource.property_names
    else
      names = xml.at_css("propfind prop").children.map {|e|
        e unless e.node_name == 'text'}.compact
      names = resource.property_names if names.empty?
      bad_request if names.empty?
    end

    host = "#{request.scheme}://#{request.host}/"

    builder = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
      xml.multistatus('xmlns' => "DAV:") do
        for r in resource.find_resources
          xml.response do
            xml.href "#{host}#{r.path.relative_path_from(Pathname(options.public))}"
            propstats xml, r.get_properties(names)
          end
        end
      end
    end

    content_type 'application/xml'

    body builder.to_xml
    multi_status
  end

  route 'PROPPATCH', '/*' do
    protected!
    path = Pathname File.join(options.public, params[:splat][0])
    xml = Nokogiri::XML request.body.read
    
    bad_request unless xml.errors.empty?
    not_found unless path.exist?
    
    resource = Dav::Resource.new path, request, options

    ns = xml.namespaces
    ns.delete 'xmlns'

    selector = if ns.empty?
      'propertyupdate set prop'
    else
      sel = ns.keys.first.split(':').last
      "#{sel}|propertyupdate #{sel}|set #{sel}|prop"
    end

    rem_selector = if ns.empty?
      'propertyupdate remove prop'
    else
      sel = ns.keys.first.split(':').last
      "#{sel}|propertyupdate #{sel}|remove #{sel}|prop"
    end

    prop_set = xml.css(selector).children.map {|e|
      e unless e.node_name == 'text'}.compact
    
    prop_rem = xml.css(rem_selector).children.map {|e|
      e unless e.node_name == 'text'}.compact

    host = "#{request.scheme}://#{request.host}/"

    builder = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
      xml.multistatus('xmlns' => "DAV:") do
        for r in resource.find_resources
          xml.response do
            xml.href "#{host}#{r.path.relative_path_from(Pathname(options.public))}"
            propstats xml, r.set_properties(prop_set)
            propstats xml, r.remove_properties(prop_rem)
          end
        end
      end
    end

    content_type 'application/xml'

    body builder.to_xml
    multi_status
  end

  put '/*' do
    protected!
    path = File.join options.public, params[:splat][0]
    conflict unless File.exists? File.dirname(path)
  
    write request.body, path
  
    created
  end

  # set upload to post as litmus webdav test fails on put here
  post '/*' do
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

  def propstats(xml, stats)
    return if stats.empty?

    for status, props in stats
      xml.propstat do
        xml.prop do
          for name, value in props
            if value.is_a?(Nokogiri::XML::DocumentFragment)
              xml << value.children.first.to_xml
              #xml.send(name) do
              #  nokogiri_convert(xml, value.children.first)
              #end
            else
              xml.send name, value
            end
          end
        end
        xml.status "HTTP/1.1 #{status.status_line}"
      end
    end
  end

  # not needed... maybe
  def nokogiri_convert(xml, element)
    if element.children.empty?
      if element.text?
        element.content
        #xml.send element.name, element.content, element.attributes
      else
        xml.send element.name, element.attributes
      end
    else
      xml.send(element.name, element.attributes) do
        element.children.each do |child|
          nokogiri_convert(xml, child)
        end
      end
    end
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
  def multi_status
    halt 207
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
