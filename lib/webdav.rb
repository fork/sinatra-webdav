Bundler.require

class WebDAV < ::Sinatra::Base
  set :root, File.expand_path('../..', __FILE__)
  disable :dump_errors
  enable :raise_errors

  SLASH = '/'
  SPACE = ' '
  STAR  = '*'
  STARS = '**'
  DASH  = '-'

  DIRECTORY_TYPE = 'directory'

  route 'MKCOL', '/*/' do
    path = File.join options.public, params[:splat][0]

    error 403 if path.include? STAR
    error 405 if File.exists? path or not File.exists? File.dirname(path)

    Dir.mkdir path

    halt 200
  end

  get '/*' do
    glob = make_glob params[:splat].first
    not_found unless glob.include? STAR or File.exists? glob
    list = Dir[glob].map! { |path| file_values path }

    haml :index, :locals => {
      :title => "/#{ glob }",
      :list => list
    }
  end

  def make_glob(path, root = options.public)
    error 403 if path.include? STARS

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

end
