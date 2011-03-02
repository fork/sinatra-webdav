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
    conflict unless resource.parent.collection?
    not_allowed if resource.exist?
    unsupported if request.body.size > 0

    responder = DAV::Responder.new { |r| resource.mkcol r }

    headers no_cache
    ok
  end

  move '*' do
    not_found unless resource.exist?
    conflict unless resource.destination.parent.collection?

    exists = resource.destination.exist?

    # TODO move this into Resource#copy
    precondition_failed if exists and not resource.overwrite?

    responder = DAV::Responder.new { |r| resource.move r }

    headers no_cache
    exists ? no_content : created
  end

  copy '*' do
    not_found unless resource.exist?
    conflict unless resource.destination.parent.collection?

    exists = resource.destination.exist?
    # TODO move this into Resource#copy
    precondition_failed if exists and not resource.overwrite?

    responder = DAV::Responder.new { |r| resource.copy r }

    headers no_cache
    exists ? no_content : created
  end

  propfind '*' do
    not_found unless resource.exist?

    xml = Nokogiri::XML request.body.read
    bad_request unless xml.errors.empty?

    content_type 'application/xml'

    responder = DAV::Responder.new { |r| resource.propfind r }
    multi_status responder
  end

  proppatch '*' do
    not_found unless resource.exist?

    xml = Nokogiri::XML request.body.read
    bad_request unless xml.errors.empty?

    headers no_cache

    responder = DAV::Responder.new { |r| resource.proppatch r }
    multi_status responder
  end

  put '*' do
    conflict unless resource.parent.collection?
    responder = DAV::Responder.new { |r| resource.put r }

    created
  end

  delete '*' do
    not_found unless resource.exist?

    responder = DAV::Responder.new { |r| resource.delete r }
    responder.status(resource.uri).ok?? ok : multi_status(responder)
  end

  # TODO implement LOCK method
  #lock '*' do
  #  headers no_cache
  #  ok
  #end
  # TODO implement UNLOCK method
  #unlock '*' do
  #  headers no_cache
  #  no_content
  #end

  get '*' do
    not_found unless resource.exist?
    bad_request if resource.collection?

    deliver_resource resource
  end

  protected

    # Overwrite this method if you need special GET behaviour
    def deliver_resource(resource)
      content_type resource.content_type
      etag resource.entity_tag
      last_modified resource.last_modified

      body resource.body
    end

end
