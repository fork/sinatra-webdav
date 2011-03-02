# encoding: UTF-8
module DAV
  module Actions

    def mkcol(responder, now = Time.now)
      unless block_given?
        properties.creation_date = now
        properties.display_name  = File.basename uri.path
        properties.resource_type = 'collection'
      else
        yield properties
      end

      responder.respond_to(uri) do |response|
        response.on(:finish) { |status| store if status.ok? }
        response.status :ok!
      end
    end
    def put(responder, now = Time.now)
      content_type = request.content_type
      content_type ||= Rack::Mime.mime_type File.extname(uri.path)

      unless block_given?
        properties.creation_date  = now
        properties.display_name   = File.basename uri.path
        properties.content_length = request.content_length
        properties.content_type   = content_type
        properties.entity_tag     = "#{ request.content_length }-#{ checksum }"
      else
        yield properties
      end

      responder.respond_to(uri) do |response|
        response.on(:finish) { |status| store if status.ok? }
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

    def copy responder, Δ = depth(:default => Infinity)
      unless collection? then destination.put(responder) { |p| properties.copy p }
      else
        destination.mkcol(responder) { |p| properties.copy p }
        Δ -= 1

        children.each do |child|
          basename = child.display_name
          basename << '/' if child.collection?

          child.destination = destination.join basename
          child.copy responder, Δ
        end unless Δ < 0
      end
    end
    def move responder, Δ = depth(:default => Infinity)
      copy responder, Δ
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
        if properties.collection?
          resource_storage.set id, nil
        else
          request.body.rewind
          resource_storage.set id, request.body.read
        end

        if request.respond_to? :properties
          request.properties.copy properties
        else
          properties.last_modified = Time.now
          properties.store
        end

        parent.children.add(self).store
      end

  end
end
