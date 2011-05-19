ROOT = File.expand_path '../..', __FILE__
require "#{ ROOT }/teststrap"
require 'stringio'


context 'Instance with Opener' do

  setup do
    klass = Struct.new :content do
      include DAV::Opener
      opener(:io) { |content| StringIO.new content }
    end

    klass.new 'content'
  end

  asserts 'result of open_as(:raw)' do
    topic.open_as(:raw) { |argument| argument }
  end.nil

  asserts 'result of open_as(:io)' do
    topic.open_as(:io) { |io| io.read }
  end.equals 'content'

  context 'of inherited class with opener for :raw' do

    setup do
      klass = Class.new topic.class do
        opener(:raw) { |content| content }
      end

      klass.new 'raw content'
    end

    asserts 'result of open_as(:raw)' do
      topic.open_as(:raw) { |raw| raw }
    end.equals 'raw content'
    asserts 'result of open_as(:io)' do
      topic.open_as(:io) { |io| io.read }
    end.equals 'raw content'

  end

end
