# Sinatra based WebDAV implementation

For an example application using OmniAuth and the FileBackend see
https://github.com/fork/farmfacts-dullahan in this directory.
It comes with a JavaScript based file manager.

## Setup

    $ git clone git@github.com:fork/sinatra-webdav.git
    $ cd sinatra-webdav
    $ bundle install

We use NGINX and Phusion Passenger for deployment but you are free to choose
any other Rack compatible webserver.


## Warnings

If you statically serve files from a directory with nginx, apache, etc... do
not point the file backend resource to this directory!


## Requirements

* Ruby 1.9.2+

litmus - WebDAV test suite runs on Linux, Solaris, FreeBSD, CygWin, and many
other Unix systems. On OS X you need XCode.

To run the litmus test suite you need to start the server in the test
directory. Then run:

    $ test/litmus_test.rb

This extracts litmus, configures, compiles and runs the test suite.


## TODO

* PLUpload in filemanager (fine tuning)
* second column in filemanager (needs synchronization)
* context menus in filemanager (copy, move, ...)
* bookmarks in filemanager
* implement LOCK and UNLOCK
* write unit tests for file backend
* implement ACL
* redis based property management
* write documentation
* implement DeltaV
* test different setups (thin, unicorn, ...)


## Contact

[Florian Aßmann](mailto:fassmann@fork.de)
