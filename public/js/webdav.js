(function(provides, $) {
	provides.WebDAV = {
		PROPFIND: function(uri, callback, depth) {
			if (typeof(depth) == 'undefined') depth = 1;

			$.ajax({
				beforeSend: function(r) { r.setRequestHeader('DEPTH', depth); },
				complete: function(request, st) {
					if (st == 'success') callback.call(this, request.responseXML);
				},
				dataType: 'text/xml',
				type: 'PROPFIND',
				url: uri
			});
		},
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
					req.setRequestHeader("OVERWRITE", 'T');
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
	};
})(window, jQuery);
