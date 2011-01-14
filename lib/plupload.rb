require "#{ File.dirname __FILE__ }/uploader"

class Put

  SUCCESS_MESSAGE = '{"jsonrpc" : "2.0", "result" : null, "id" : "id"}'
  FAILED_OPEN_TMP_ERROR = '{"jsonrpc" : "2.0", "error" : {"code": 100, "message": "Failed to open temp directory."}, "id" : "id"}'
  FAILED_MOVE_FILE_ERROR = '{"code": 103, "message": "Failed to move uploaded file."}, "id" : "id"}'
  FAILED_OPEN_ERROR = '{"jsonrpc" : "2.0", "error" : {"code": 101, "message": "Failed to open input or output stream."}, "id" : "id"}'

  def initialize(params, sinatra)
    @chunk = params['chunk'].to_i
    @chunks = params['chunks'].to_i

    @tempfile = params[:file][:tempfile]
    @tmp_dir = File.join sinatra.root, 'tmp', 'plupload'
    @tmp_path = File.join @tmp_dir, params['name'].to_s.gsub(/[^\w\._]+/, '')
    #fixes chrome generating strange blob... filename
    filename = File.basename params[:splat].first
    purged_filename = filename.gsub(/[^\w\._]+/, '')
    destination_dir = File.dirname params[:splat].first
    @public_path = sinatra.public
    @path = File.join @public_path, destination_dir, purged_filename

    append = params[:chunks] && Integer(params[:chunk]) > 0
    @mode = append ? 'a' : ::File::TRUNC | ::File::WRONLY | ::File::CREAT
  end

  def process
    unless tmp_dir?
      return [false, FAILED_OPEN_TMP_ERROR]
    else
      File.open(@tmp_path, @mode) do |file|
        while iochunk = @tempfile.read(1024**2)
          file.write iochunk
        end
      end
    end
    # copy tmp file to destination and remove tmp file if it was the last chunk or file was transferred without using chunks
    if @chunk == @chunks || (@chunks > 0 && @chunk == (@chunks - 1))
      move_to_destination
    end
    [true, SUCCESS_MESSAGE]
  rescue FailedMoveFile
    [false, FAILED_MOVE_FILE_ERROR]
  rescue IOError
    [false, FAILED_OPEN_ERROR]
  end

  class FailedMoveFile < Exception; end

  protected

  def move_to_destination
    unless FileUtils.mv(@tmp_path, @path, :force => true) and 
        Uploader::Processing.new(@path, @public_path).process!
      remove_tmp_file
      raise FailedMoveFile
    end
  end

  def remove_tmp_file
    FileUtils.rm @tmp_path rescue nil
  end

  def tmp_dir?
    FileUtils.mkpath(@tmp_dir) && File.directory?(@tmp_dir)
  end

end
