# Sinatra based WebDAV implementation

For an example application using OmniAuth and the FileBackend see
[dullahan](https://github.com/fork/farmfacts/tree/master/dullahan).

## Setup

    $ git clone git@github.com:fork/sinatra-webdav.git
    $ cd sinatra-webdav
    $ bundle install

We use NGINX and Phusion Passenger for deployment but you are free to choose
any other Rack compatible webserver.


## Warning!

If you serve files statically with nginx, apache, etc... don't make their
location the document root.
If you need them to be served statically instead use another server instance
w/o sinatra-webdav or enable X-Sendfile.


## Requirements

Ruby 1.9.2


## Development

We choose the litmus testing suite for the time being. It runs on Linux,
Solaris, FreeBSD, CygWin, and many other Unix systems.

You need a working build system (autoconf, make, ...).

To run the litmus test suite:

    1. $ cd test
    2. $ passenger start -d
    3. $ ./litmus_test.rb

This extracts litmus, configures, compiles and runs it.


## TODO

* redis based property management
* implement LOCK and UNLOCK
* implement ACL
* write unit tests for file backend
* write documentation
* implement DeltaV
* test different setups (thin, unicorn, ...)


## Contact

[Florian Aßmann](mailto:fassmann@fork.de)
