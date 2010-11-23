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
		MOVE: function(url, dest, callback) {
			$.ajax({
				success: callback,
				error: function(req) {
					if(req.status == 401) window.location = '/auth/cas';
				},
				type: 'MOVE',
				beforeSend: function(req) {
					req.setRequestHeader("DESTINATION", dest);
					req.setRequestHeader("OVERWRITE", 'T');
				},
				url: url
			});
		},
		COPY: function(url, dest, callback) {
			$.ajax({
				success: callback,
				error: function(req) {
					if(req.status == 401) window.location = '/auth/cas';
				},
				type: 'COPY',
				beforeSend: function(req) {
					req.setRequestHeader("DESTINATION", dest);
				},
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
