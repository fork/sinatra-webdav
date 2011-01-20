# Sinatra based WebDAV implementation
#
# see http://www.webdav.org/specs/rfc4918.html
class WebDAV::Base < ::Sinatra::Base
  enable :raise_errors
  set :root, File.expand_path('../..', __FILE__)
  disable :dump_errors, :static

  register WebDAV::Verbs
  helpers WebDAV::Statuses, WebDAV::Convenience

  # For the time being we use the DAV 1 compliance class until we support
  # the LOCK methods.
  #
  # Add methods in the 'Allow' header when we support them.
  #
  # see http://www.webdav.org/specs/rfc4918.html#rfc.section.18
  OPTIONS_HEADER = { 'DAV' => '1', 
    'Allow' => 'OPTIONS, HEAD, GET, PUT, DELETE, MKCOL, COPY, MOVE, PROPFIND, PROPPATCH' }

  route 'OPTIONS', '*' do
    # FIXME no GET on collections, so make this a resource method
    headers OPTIONS_HEADER
    ok
  end

  mkcol '*' do
    conflict if resource != resource.parent && !resource.parent.exist?
    not_allowed if resource.exist?
    unsupported if request.body.size > 0

    resource.mkcol

    ok
  end

  move '*' do
    not_found unless resource.exist?
    conflict unless destination.parent.exist?

    exists = destination.exist?
    precondition_failed if exists and not overwrite?

    resource.move destination, depth(:except => 1, :default => DAV::Infinity)

    exists ? no_content : created
  end

  copy '*' do
    not_found unless resource.exist?
    conflict unless destination.parent.exist?

    exists = destination.exist?
    precondition_failed if exists and not overwrite?

    resource.copy destination, depth(:except => 1, :default => DAV::Infinity)

    exists ? no_content : created
  end

  propfind '*' do
    not_found unless resource.exist?

    xml = Nokogiri::XML request.body.read
    bad_request unless xml.errors.empty?

    content_type 'application/xml'
    body resource.properties.to_xml(xml, depth(:default => DAV::Infinity))

    multi_status
  end

  proppatch '*' do
    not_found unless resource.exist?

    xml = Nokogiri::XML request.body.read
    bad_request unless xml.errors.empty?

    content_type 'application/xml'
    body resource.properties.update(xml)

    multi_status
  end

  put '*' do
    conflict unless resource.parent.exist?
    resource.put request.body

    created
  end

  delete '*' do
    not_found unless resource.exist?
    resource.delete

    ok
  end

  # TODO implement LOCK/UNLOCK methods
  route('LOCK', '*') { ok }
  route('UNLOCK', '*') { no_content }

  get '*' do
    not_found unless resource.exist?
    bad_request if resource.collection?

    content_type resource.type
    body resource.get
  end

end
