* add documentation and unit test
* merge callbacks into preconditions and postconditions
* move WebDAV::Base logic into preconditions
* drop Sinatra dependency
* replace global lock on relations with a per relation based one
* lock properties, too
* provide LOCK and UNLOCK methods
* improve DAV::Base#open\_as interface
* let responder cache resource objects
* bypass DAV method implementation with Backend implementations
* implement ACL and Delta-V
* test with different Ruby versions
* make OPTIONS work on resource
