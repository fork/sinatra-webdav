# encoding: UTF-8
module DAV
  module Actions

    def mkcol(responder, now = Time.now)
      properties.creation_date = now
      properties.display_name  = File.basename uri.path
      properties.resource_type = 'collection'

      responder.respond_to(uri) do |response|
        response.on(:finish) { |status| store_all if status.ok? }
        response.status :ok!
      end
    end
    def put(responder, now = Time.now)
      content_type = request.content_type
      content_type ||= Rack::Mime.mime_type File.extname(uri.path)

      properties.creation_date  = now
      properties.display_name   = File.basename uri.path
      properties.content_length = request.content_length
      properties.content_type   = content_type
      properties.entity_tag     = "#{ request.content_length }-#{ checksum }"

      responder.respond_to(uri) do |response|
        response.on(:finish) { |status| store_all if status.ok? }
        response.status :ok!
      end
    end
    def delete(responder)
      children.each { |child| child.delete responder }

      responder.respond_to uri do |response|
        response.precondition do |condition|
          children.uris.all? { |uri| responder.status(uri).ok? } or
          condition.failed_dependency!
        end

        response.status do |status|
          status.ok! if response.precondition.ok?
        end

        response.on(:finish) do |status|
          if status.ok?
            parent.children.remove(self).store
            properties.delete
            resource_storage.delete id
          end
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
      unless collection?
        destination.put responder, now
        properties.copy destination.properties
      else
        destination.mkcol responder, now
        properties.copy destination.properties
        Δ -= 1

        children.each do |child|
          basename = child.display_name
          basename << '/' if child.collection?

          child.destination = destination.join basename
          child.copy responder, Δ, now
        end unless Δ < 0
      end
    end
    def move responder, Δ = depth(:default => Infinity)
      copy responder, Δ, properties.creation_date
      delete responder
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

    protected

      def store
        content = nil

        unless properties.collection?
          request.body.rewind
          content = request.body.read
        end

        resource_storage.set id, content
      end
      def store_all
        store

        properties.last_modified = Time.now
        properties.store

        parent.children.add self unless parent == self
        parent.children.store
      end

  end
end
