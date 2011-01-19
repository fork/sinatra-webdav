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
	Controller.defaultType = 'application/octet-stream';

	Controller['directory'] = function(url) {
		$.bbq.pushState({ url: url });
	};

	provides.Resource = Resource;
	provides.Controller = Controller;
})(window, jQuery);
