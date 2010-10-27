(function(provides, $) {
	function Controller(type) {
		return Controller[type] || Controller[Controller.defaultType];
	};
	Controller['application/octet-stream'] = function(url) {
		window.open(url);
	};
	Controller.defaultType = 'application/octet-stream';

	Controller['directory'] = function(url) {
		var $$ = $(this);
		WebDAV.GET(url, function(html) {
			var data = $(html).find('.data').html();
			$$.trigger('webdav.directory', [url, data]);
		});
	};

	provides.Controller = Controller;
})(window, jQuery);
