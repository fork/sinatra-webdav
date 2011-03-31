# encoding: UTF-8
module DAV
  module Actions

    def get
      content
    end

    def mkcol(responder, now = Time.now)
      # TODO add support for MKCOL with body
      self.content = nil

      properties.creation_date = now
      properties.display_name  = File.basename decoded_uri.path
      properties.resource_type = 'collection'

      responder.respond_to(uri) do |response|
        response.on(:finish) { |status| store_all if status.ok? }
        response.status :ok!
      end
    end
    def put(responder, now = Time.now)
      unless defined? @content
        request.body.rewind
        self.content = request.body.read

        content_type = request.content_type
        # RADAR ignore charset for the time being
        content_type &&= content_type.split(';').first
        content_type ||= Rack::Mime.mime_type File.extname(uri.path)

        properties.display_name = File.basename decoded_uri.path
        properties.content_type = content_type
      end
      properties.creation_date = now

      responder.respond_to(uri) do |response|
        response.on(:finish) { |status| store_all if status.ok? }
        response.status :ok!
      end
    end
    def delete(responder)
      children.each { |child| child.delete responder }

      responder.respond_to uri do |response|
        response.precondition do |condition|
          success = children.uris.all? do |uri|
            status = responder.status(uri) and status.ok?
          end
          condition.failed_dependency! unless success
        end

        response.status do |status|
          status.ok! if response.precondition.ok?
        end

        response.on(:finish) do |status|
          delete_all if status.ok?
        end
      end
    end

    def propfind responder, Δ = depth(:default => Infinity)
      responder.respond_to(uri) { |req| properties.find request.body, req }

      Δ ||= depth :default => Infinity
      Δ -= 1

      children.each { |c| c.propfind responder, Δ } unless Δ < 0
    end
    def proppatch(responder)
      responder.respond_to uri do |response|
        response.on(:finish) { |status| properties.store if status.ok? }
        properties.patch request.body, response
      end
    end

    def copy responder, Δ = depth(:default => Infinity), now = Time.now
      destination.put responder, now
      Δ -= 1

      if collection?
        children.each do |child|
          basename = File.basename child.uri.path
          basename << '/' if child.collection?

          child.destination = destination.join basename
          child.copy responder, Δ, now
        end
      end unless Δ < 0
    end
    def move responder, Δ = depth(:default => Infinity)
      copy responder, Δ, properties.creation_date
      delete responder unless destination.id == id
    end

    def lock(*args)
      raise NotImplementedError
    end
    def unlock(*args)
      raise NotImplementedError
    end
    def search(*args)
      raise NotImplementedError
    end

  end
end
