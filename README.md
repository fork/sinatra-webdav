# Sinatra based WebDAV implementation


## Setup

    $ git clone git@github.com:fork/webdav.git
    $ cd webdav
    $ bundle install

I used NGINX and Phusion Passenger for deployment but you are free to choose
any other Rack compatible webserver.


## Attachments

nginx.conf:

    # snip
    server {
        listen       80;
        server_name  webdav;

        charset      utf-8;

        passenger_enabled on;

        root         webdav/public;
        error_log    webdav/log/development.log debug;
        access_log   webdav/log/access.log;
    }
    # snip
