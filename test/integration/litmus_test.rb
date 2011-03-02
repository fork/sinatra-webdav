#!/usr/bin/env ruby

require 'pathname'

PORT = ARGV[0] || 3000

def enter(path)
  working_directory = Dir.getwd
  Dir.chdir path
  yield Pathname(path)
ensure
  Dir.chdir working_directory
end

enter File.expand_path('../..', __FILE__) do |root|

  # try to restart passenger
  pid_file = root.join 'tmp', 'pids', "passenger.#{ PORT }.pid"
  Process.kill 'HUP', Integer(pid_file.read) if pid_file.exist?

  # create public directory
  root.join('public').mkdir unless root.join('public').directory?

  # deploy litmus
  litmus = root.join 'litmus'

  unless litmus.join('Makefile').exist?
    puts 'Preparing litmus...'
    system 'tar', '-xzf', 'litmus-0.12.1.tar.gz'
    system 'mv', 'litmus-0.12.1', 'litmus'

    enter litmus do |*|
      system './configure'
      system 'make'
    end
  end

  # hit'n'go
  enter litmus do |*|
    root.join('htdocs').mkdir
    system 'make', "URL=http://localhost:#{ PORT }/", 'check'
    root.join('htdocs').rmtree
  end

end
