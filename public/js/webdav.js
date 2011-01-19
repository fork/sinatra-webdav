(function(provides, $) {
	provides.WebDAV = {
		PROPFIND: function(uri, callback, depth) {
			if (typeof(depth) == 'undefined') depth = 1;

			$.ajax({
				beforeSend: function(r) {
					r.setRequestHeader('DEPTH', depth);
				},
				complete: function(request, status) {
					if (status == 'success') {
						callback.call(this, request.responseXML);
					}
				},
				dataType: 'text/xml',
				type: 'PROPFIND',
				url: uri
			});
		},
		GET: function(url, callback) {
			$.ajax({
				complete: function(request, status) {
					if (status == 'success') {
						callback.call(this, request.responseXML);
					}
				},
				url: url
			});
		},
		MKCOL: function(url, callback) {
			$.ajax({
				complete: function(request, status) {
					if (status == 'success') {
						callback.call(this, request.responseXML);
					}
				},
				type: 'MKCOL',
				url: url
			});
		},
		DELETE: function(url, callback) {
			$.ajax({
				complete: function(request, status) {
					if (status == 'success') {
						callback.call(this, request.responseXML);
					}
				},
				type: 'DELETE',
				url: url
			});
		},
		COPY: function(url, destination, callback, overwrite) {
			if (typeof(overwrite) == 'undefined') overwrite = 'T';

			$.ajax({
				beforeSend: function(req) {
					req.setRequestHeader("DESTINATION", destination);
					req.setRequestHeader("OVERWRITE", overwrite);
				},
				complete: function(request, status) {
					if (status == 'success') {
						callback.call(this, request.responseXML);
					}
				},
				type: 'COPY',
				url: url
			});
		},
		MOVE: function(url, destination, callback, overwrite) {
			if (typeof(overwrite) == 'undefined') overwrite = 'T';

			$.ajax({
				beforeSend: function(req) {
					req.setRequestHeader("DESTINATION", destination);
					req.setRequestHeader("OVERWRITE", overwrite);
				},
				complete: function(request, status) {
					if (status == 'success') {
						callback.call(this, request.responseXML);
					}
				},
				type: 'MOVE',
				url: url
			});
		}
	};
})(window, jQuery);
