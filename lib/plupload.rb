class PLUpload < Struct.new(:name, :chunks, :index, :source)

  Success = Class.new(String) { def ok?; true end }
  SUCCEEDED = Success.new '{"jsonrpc" : "2.0", "result" : null, "id" : "id"}'

  Failure = Class.new(String) { def ok?; false end }
  FAILED = Failure.new '{"jsonrpc" : "2.0", "error" : {"code": 101, "message": "Failed to open input or output stream."}, "id" : "id"}'

  NEITHER_A_WORD_CHARACTER_NOR_A_DOT = /[^\w\.]+/

  @@temp = File.join Dir.getwd, 'tmp'
  def self.temp=(temp)
    @@temp = temp
  end
  def self.temp(temp)
    @@temp
  end

  def self.process(params)
    name   = params['name']
    index  = params['chunk'].to_i
    chunks = params['chunks'].to_i
    source = params[:file][:tempfile]

    instance = new name, chunks, index, source
    instance.process { |io| yield io }

    return SUCCEEDED
  rescue => e
    $stderr.puts e, e.backtrace
    return FAILED
  end

  def process
    tempfile do |io|
      blocksize = io.stat.blksize
      blocksize = 4096 unless blocksize and blocksize > 0
      while data = source.read(blocksize)
        io << data
      end
    end

    if not chunked? or finished?
      tempfile('r') { |io| yield io }
      FileUtils.rm path rescue nil
    end
  end

  protected

    def finished?
      chunks - index == 1
    end
    def chunked?
      chunks > 0
    end
    def mode
      return 'a' if chunked?
      File::TRUNC | File::WRONLY | File::CREAT
    end

    # Returns path with normalized filename
    def path
      File.join @@temp, name.gsub(NEITHER_A_WORD_CHARACTER_NOR_A_DOT, '')
    end

    def tempfile(mode = mode)
      FileUtils.mkpath @@temp unless File.directory? @@temp
      File.open(path, mode) { |io| yield io }
    end

end
