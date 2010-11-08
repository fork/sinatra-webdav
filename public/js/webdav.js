(function(provides, $) {
	provides.WebDAV = {
		GET: function(url, callback) {
			$.ajax({
				// error: func...
				success: callback,
				error: function(req) {
					if(req.status == 401) window.location = '/auth/cas';
				},
				url: url
			});
		},
		MKCOL: function(url, callback) {
			$.ajax({
				success: callback,
				error: function(req) {
					if(req.status == 401) window.location = '/auth/cas';
				},
				type: 'MKCOL',
				url: url
			});
		},
		DELETE: function(url, callback) {
			$.ajax({
				success: callback,
				error: function(req) {
					if(req.status == 401) window.location = '/auth/cas';
				},
				type: 'DELETE',
				url: url
			});
		}
	}
})(window, jQuery);
