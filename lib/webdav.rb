# Sinatra based WebDAV implementation
#
# see http://www.webdav.org/specs/rfc4918.html
class WebDAV < ::Sinatra::Base
  # Integrates hoptoad...
  #use HoptoadNotifier::Rack
  enable :raise_errors

  # Test hoptoad integration...
  get('/hoptoad') { raise 'Bam!' }

  set :root, File.expand_path('../..', __FILE__)
  disable :dump_errors, :static

  # Unless we reenable OmniAuth we don't need sessions.
  #enable :sessions

  mime_type :include, 'text/html'

  register Verbs

  helpers do
    def protected!
      # TODO is return_to uri needed?

      # USE TO TEST WITH LITMUS (and comment out authorized stuff)
      settings.set :public, File.join(settings.root, CUSTOM_PUBLIC)
      DAV::Resource.root = File.join(settings.root, CUSTOM_PUBLIC)

      # @auth ||= Rack::Auth::Basic::Request.new request.env
      # 
      # @auth.provided? && @auth.basic? && @auth.credentials == %w[ admin pr0t3ct ] or
      # request.env['HTTP_ORIGIN'] == 'http://vizard.fork.de' or
      # begin
      #   response['WWW-Authenticate'] = 'Basic realm="JH Stiftung"'
      #   halt 401
      # end

      #unauthorized unless authorized?
    end
    def request_uri
      URI URI.escape(request.url)
    end
    def resource
      @resource ||= DAV::Resource.new request_uri
    end
    def destination_uri
      URI request.env['HTTP_DESTINATION']
    end
    def destination
      @destination ||= resource.join destination_uri
    end

    def ok(*args)
      halt 200, *args
    end
    def created(*args)
      halt 201, *args
    end
    def no_content(*args)
      halt 204, *args
    end
    def multi_status(*args)
      halt 207, *args
    end
    def bad_request(*args)
      error 400, *args
    end
    def unauthorized(*args)
      error 401, *args
    end
    def forbidden(*args)
      error 403, *args
    end
    def not_allowed(*args)
      error 405, *args
    end
    def conflict(*args)
      error 409, *args
    end
    def precondition_failed(*args)
      error 412, *args
    end
    def unsupported(*args)
      error 415, *args
    end

    MAPPING = { '0' => 0, '1' => 1, 'infinity' => DAV::Infinity }
    def depth(options)
      mapping = MAPPING
      exceptions = Array options[:except]

      mapping = mapping.inject({}) do |mem, (key, value)|
        mem[key] = value unless exceptions.include? value
        mem
      end unless exceptions.empty?

      mapping.fetch request.env['HTTP_DEPTH'], options[:default]
    end
    def overwrite?
      request.env['HTTP_OVERWRITE'] == 'T'
    end
    def authorized?
      not session[:user].nil?
    end
  end

  # testuser 'admin' 'whatever' / folder group_files/admins needed in root
  #use OmniAuth::Builder do
  #  provider OmniAuth::Strategies::CAS, { :cas_server => 'https://cas.fork.de',
  #    :cas_service_validate_url => 'https://cas.fork.de/proxyValidate' }
  #end

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
    'Allow' => 'OPTIONS, HEAD, GET, PUT, DELETE, MKCOL, COPY, MOVE, PROPFIND, PROPPATCH' }

  route 'OPTIONS', '*' do
    headers OPTIONS_HEADER
    ok
  end

  mkcol '*' do
    protected!

    conflict if resource != resource.parent && !resource.parent.exist?
    not_allowed if resource.exist?
    unsupported if request.body.size > 0

    resource.mkcol

    ok
  end

  move '*' do
    protected!

    not_found unless resource.exist?
    conflict unless destination.parent.exist?

    exists = destination.exist?
    precondition_failed if exists and not overwrite?

    resource.move destination, depth(:except => 1, :default => DAV::Infinity)

    exists ? no_content : created
  end

  copy '*' do
    protected!
    path = params[:splat].first

    not_found unless resource.exist?
    conflict unless destination.parent.exist?

    exists = destination.exist?
    precondition_failed if exists and not overwrite?

    resource.copy destination, depth(:except => 1, :default => DAV::Infinity)

    exists ? no_content : created
  end

  propfind '/*' do
    protected!
    path = Pathname File.join(options.public, params[:splat][0])
    xml = Nokogiri::XML request.body.read
    
    bad_request unless xml.errors.empty?
    not_found unless path.exist?
    
    # resource = Dav::Resource.new path, request, options
    # 
    # if prop = xml.at_css("propfind prop")
    #   names = prop.children.map {|e|
    #     e unless e.node_name == 'text'}.compact
    #   names = resource.property_names if names.empty?
    #   bad_request if names.empty?
    # else
    #   #xml.at_css("propfind allprop")
    #   names = resource.property_names
    # end
    # 
    # host = "#{ request.scheme }://#{ request.host_with_port }"
    # 
    # construct = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |builder|
    #   builder.multistatus('xmlns' => "DAV:") do
    #     for r in resource.find_resources
    #       builder.response do
    #         # RADAR in my reality, we don't need a host...
    #         builder.href "#{ host }#{ r.public_path }"
    #         propstats builder, r.get_properties(names)
    #       end
    #     end
    #   end
    # end

    content_type 'application/xml'

    body resource.properties.to_xml(xml, depth(:default => DAV::Infinity))
    #body construct.to_xml
    multi_status
  end

  proppatch '/*' do
    protected!
    path = Pathname File.join(options.public, params[:splat][0])
    xml = Nokogiri::XML request.body.read
    
    bad_request unless xml.errors.empty?
    not_found unless path.exist?
    
    # resource = Dav::Resource.new path, request, options
    # 
    # ns = xml.namespaces
    # ns.delete 'xmlns'
    # 
    # selector = if ns.empty?
    #   'propertyupdate set prop'
    # else
    #   sel = ns.keys.first.split(':').last
    #   "#{sel}|propertyupdate #{sel}|set #{sel}|prop"
    # end
    # 
    # rem_selector = if ns.empty?
    #   'propertyupdate remove prop'
    # else
    #   sel = ns.keys.first.split(':').last
    #   "#{sel}|propertyupdate #{sel}|remove #{sel}|prop"
    # end
    # 
    # prop_set = xml.css(selector).children.map {|e|
    #   e unless e.node_name == 'text'}.compact
    # 
    # prop_rem = xml.css(rem_selector).children.map {|e|
    #   e unless e.node_name == 'text'}.compact
    # 
    # host = "#{request.scheme}://#{request.host}/"
    # 
    # construct = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |builder|
    #   builder.multistatus('xmlns' => "DAV:") do
    #     for r in resource.find_resources
    #       builder.response do
    #         builder.href "#{ host }#{ r.path.relative_path_from Pathname(options.public) }"
    #         propstats builder, r.set_properties(prop_set)
    #         propstats builder, r.remove_properties(prop_rem)
    #       end
    #     end
    #   end
    # end

    content_type 'application/xml'

    #body construct.to_xml
    
    body resource.properties.update(xml)
    multi_status
  end

  put '*' do
    protected!

    conflict unless resource.parent.exist?
    resource.put request.body

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

    not_found unless resource.exist?
    resource.delete

    ok
  end

  get '/:locale/teaser' do
    protected!
    teaser = Dir["#{settings.public}/#{params[:locale]}/**/#{params[:type]}.include"]
    teaser.map! {|t|
      {
        :html => File.read(t),
        :ssi => URI.escape("<!--#include virtual=\"#{t.sub(settings.public, '')}\" -->")
      } 
    }.join

    slim :teaser, :locals => {:html_teasers => teaser}, :layout => false
  end

  get '*' do
    protected!

    if resource.exist? and not resource.collection?
      content_type resource.type
      body resource.get
      # what about open images in new tab...
      #send_file(glob) if not glob.include? STAR and File.file? glob
      #return File.read(glob) if not glob.include? STAR and File.file? glob
    else
      # TODO use propfind with DEPTH 1 instead
      # TODO make this a AutoIndex extension
      root = options.public
      glob = make_glob params[:splat].first, root

      unless glob.include? STAR
        # why forbidden? i need this...
        #forbidden if glob.include? STARS
        not_found
      else
        list = Dir[glob].map! { |path| file_values path, root }
        path = glob[root.length..-1]

        slim :index, :locals => {
          :title => "/#{ path }",
          :list => list
        }
      end
    end
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

  # def propstats(xml, stats)
  #   return if stats.empty?
  # 
  #   for status, props in stats
  #     xml.propstat do
  #       xml.prop do
  #         for name, value in props
  #           if value.is_a?(Nokogiri::XML::DocumentFragment)
  #             xml << value.children.first.to_xml
  #             #xml.send(name) do
  #             #  nokogiri_convert(xml, value.children.first)
  #             #end
  #           else
  #             xml.send name, value
  #           end
  #         end
  #       end
  #       xml.status "HTTP/1.1 #{status.status_line}"
  #     end
  #   end
  # end
  # 
  # # not needed... maybe
  # def nokogiri_convert(xml, element)
  #   if element.children.empty?
  #     if element.text?
  #       element.content
  #       #xml.send element.name, element.content, element.attributes
  #     else
  #       xml.send element.name, element.attributes
  #     end
  #   else
  #     xml.send(element.name, element.attributes) do
  #       element.children.each do |child|
  #         nokogiri_convert(xml, child)
  #       end
  #     end
  #   end
  # end

  def no_cache_header
    { 'Content-type' => 'text/plain; charset=UTF-8',
      'Expires' => 'Mon, 26 Jul 1997 05:00:00 GMT',
      'Last-Modified' => Time.now.strftime("%a, %d %b %Y %H:%M:%S GMT"), 
      'Cache-Control' => 'no-store, no-cache, must-revalidate',
      'Pragma' => 'no-cache' }
  end

end
