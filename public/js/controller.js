(function(provides, $) {
	function Resource() {
		var resource = {};
		resource.href = $('href', this).text();

		var names  = resource.href.split('/'),
		    offset = names.length - (/\/$/.test(resource.href) ? 2 : 1);
		resource.basename = names[offset];
		resource.basename = decodeURI(resource.basename);

		var p = $('prop', this);
		resource.contentType   = p.find('getcontenttype').text();
		resource.contentLength = p.find('getcontentlength').text() * 1;
		resource.lastModified  = new Date(p.find('getlastmodified').text());

		return resource;
	}

	function Controller(type) {
		return Controller[type] || Controller[Controller.defaultType];
	};
	Controller['application/octet-stream'] = function(url) {
		window.open(url);
	};
	Controller['text/html'] = function(url) {
		var host = location.protocol + '//' + location.host;
		var path = url.replace(/https?:\/\//, '');

		window.location = 'http://vizard.fork.de/' + path + '?path=' + url +
			'&origin='      + host +
			'&return='      + location.href +
			'&handler='     + host + '/application/vizard/handler.js' +
			'&vizardcss='   + host + '/application/vizard/styles.css' +
			'&cktemplates=' + host + '/application/vizard/templates.js';
	};
	Controller.defaultType = 'application/octet-stream';

	Controller['directory'] = function(url) {
		var $$ = $(this);
		WebDAV.PROPFIND(url, function(multistatus) {
			$$.data('resources', $('response:gt(0)', multistatus).map(Resource));
			$$.data('href', url);
			$$.trigger('webdav.directory');
		});
	};

	provides.Resource = Resource;
	provides.Controller = Controller;
})(window, jQuery);
