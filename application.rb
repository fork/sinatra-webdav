root = File.dirname __FILE__

Bundler.require :example

# RADAR remove this when sinatra natively supports the slim method
require "#{ root }/lib/sinatra/templates/slim"

require "#{ root }/lib/plupload"
PLUpload.temp = File.join root, 'tmp'

DAV::Resource.backend = DAV::FileBackend
DAV::Resource.root = File.join root, 'htdocs'

File.directory? DAV::Resource.root or
raise 'Resource root needs to be configured!'

HoptoadNotifier.configure do |config|
  config.api_key = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
end

# RADAR remove this monkey-patch when we have a valid SSL certificate
class OmniAuth::Strategies::CAS::ServiceTicketValidator
  def get_service_response_body
    result = ''
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.use_ssl = @uri.port == 443 || @uri.instance_of?(URI::HTTPS)

    # MONKEY-PATCH BEGIN

    # ... until we have an official certificate
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    # MONKEY-PATCH END

    http.start do |c|
      response = c.get "#{@uri.path}?#{@uri.query}", VALIDATION_REQUEST_HEADERS
      result = response.body
    end
    result
  end
end

class Application < WebDAV::Base

  use Rack::Sendfile

  # Exception Handling
  configure :production do
    use HoptoadNotifier::Rack
    get('/hoptoad') { raise 'Bam!' }
  end

  # Server Side Includes
  mime_type :include, 'text/html'

  # Authentication
  use OmniAuth::Strategies::CAS,
      :cas_server               => 'https://rubycas.fork.de',
      :cas_service_validate_url => 'https://rubycas.fork.de/proxyValidate'
  enable :sessions

  get '/auth/:name/callback' do
    session[:user] = request.env['omniauth.auth']
    redirect '/'
  end

  get '/logout' do
    session.delete :user
    redirect '/'
  end

  helpers do
    def authorized?
      session.member? :user
    end
  end

  before {
    redirect '/auth/cas' unless authorized? or request.path =~ %r'^/auth/cas'
  }

  # support PLUploads...
  post '*' do
    conflict unless resource.parent.exist?

    # RADAR Chrome generates strange filenames...
    response = PLUpload.process(params) { |io| resource.put io }

    headers no_cache
    headers 'Content-type' => 'application/json; charset=UTF-8'

    conflict response unless response.ok?

    created response
  end

  # Deliver JavaScript client...
  set :views, "#{ File.dirname __FILE__ }/views"
  get '*' do
    not_found unless resource.exist?

    unless resource.collection?
      content_type resource.type
      body resource.get
    else
      if resource.basename == '/'
        slim :index, :locals => { :title => 'WebDAV' }
      else 
        url = request.path
        url << '/' unless url =~ /\/$/

        redirect "/#url=#{ url }"
      end
    end
  end

end
