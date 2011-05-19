module Litmus

  @enabled = false
  @tests   = Hash.new { |h, k| h[k] = [] }

  def copymove(*sections)
    sections.each { |section| @tests['copymove'][section] = true }
  end

  def init(header)
    return unless header

    test = header[/^[^:]+/]
    section = header[/\d+/].to_i

    @enabled = @tests[test][section]
    puts "==========#{ '=' * header.length }"
    puts "Capturing #{ header }"
    puts "==========#{ '=' * header.length }"
  end

  def reset!
    @enabled = false
  end

  def puts(*args)
    return unless @enabled
    STDERR.puts(*args)
    STDERR.puts yield if block_given?
  end

  extend self

end
