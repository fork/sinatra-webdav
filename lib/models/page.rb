class Page < Struct.new(:document)

  def self.open(string_or_io)
    document = Nokogiri::XML string_or_io
    new document
  end

  def css(selector)
    document.css selector
  end
  def meta(name)
    css 'meta[name="%s"]' % name
  end
  def keywords
    meta('keywords').map { |n| n['content'] }.join.
    split(',').each { |keyword| keyword.strip! }
  end

end
