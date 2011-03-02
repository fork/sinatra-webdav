module WebDAV::Verbs
  def mkcol(path, opts={}, &bk)     route 'MKCOL',     path, opts, &bk end
  def copy(path, opts={}, &bk)      route 'COPY',      path, opts, &bk end
  def move(path, opts={}, &bk)      route 'MOVE',      path, opts, &bk end
  def propfind(path, opts={}, &bk)  route 'PROPFIND',  path, opts, &bk end
  def proppatch(path, opts={}, &bk) route 'PROPPATCH', path, opts, &bk end
# RADAR already exist?
#  def lock(path, opts={}, &bk)      route 'LOCK',      path, opts, &bk end
#  def unlock(path, opts={}, &bk)    route 'UNLOCK',    path, opts, &bk end
end
