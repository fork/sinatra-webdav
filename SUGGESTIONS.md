* Improve architecture
    * Drop/Merge Callbacks in favor of preconditions and postconditions
    * Move WebDAV::Base logic into preconditions
    * Drop Sinatra dependency

* Improve performance
    * Bypass DAV method implementation with Backend implementations
