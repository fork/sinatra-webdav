module WebDAV::Statuses

  def ok(*args)
    halt 200, *args
  end
  def created(*args)
    halt 201, *args
  end
  def no_content(*args)
    halt 204, *args
  end
  def multi_status(responder, *args)
    content_type 'application/xml'
    body responder.to_xml
    
    halt 207, *args
  end
  def bad_request(*args)
    halt 400, *args
  end
  def unauthorized(*args)
    halt 401, *args
  end
  def forbidden(*args)
    halt 403, *args
  end
  def not_allowed(*args)
    halt 405, *args
  end
  def conflict(*args)
    halt 409, *args
  end
  def precondition_failed(*args)
    halt 412, *args
  end
  def unsupported(*args)
    halt 415, *args
  end

end
