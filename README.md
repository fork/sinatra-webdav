# Sinatra based WebDAV implementation

For an example application using OmniAuth and the FileBackend see
application.rb in this directory.
It comes with a simple JavaScript based file manager.

## Setup

    $ git clone git@github.com:fork/webdav.git
    $ cd webdav
    $ bundle install

We use NGINX and Phusion Passenger for deployment but you are free to choose
any other Rack compatible webserver.


## Warnings

If you statically server files from a directory with nginx, apache, etc... do
not point the file backed resource to this directory!


## Requirements

Ruby 1.9.2 and Bundler are required.

litmus - WebDAV test suite runs on Linux, Solaris, FreeBSD, CygWin, and many
other Unix systems. On OS X you need XCode.

To run the litmus test suite you need to start the server in the test
directory. Then run:

    $ ./litmus_test.rb

This extracts litmus, configures, compiles and runs the test suite.


## TODO

* PLUpload in filemanager
* second column in filemanager
* context menus in filemanager
* bookmarks in filemanager
* implement LOCK and UNLOCK
* write unit tests
* implement ACL
* write documentation
* implement DeltaV
* test different setups (thin, unicorn, ...)


## Contact

Florian Aßmann (fassmann@fork.de)
