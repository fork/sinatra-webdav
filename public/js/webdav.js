(function(provides, $) {
	provides.WebDAV = {
		GET: function(url, callback) {
			$.ajax({
				// error: func...
				success: callback,
				url: url
			});
		},
		MKCOL: function(url, callback) {
			$.ajax({
				success: callback,
				type: 'MKCOL',
				url: url
			});
		},
		DELETE: function(url, callback) {
			$.ajax({
				success: callback,
				type: 'DELETE',
				url: url
			});
		}
	}
})(window, jQuery);
