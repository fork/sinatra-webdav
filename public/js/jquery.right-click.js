(function(fn) {

	function handler(callback, context) {
		return function(e) {
			if (e.which == 3) { callback.call(context || this, e); }
			return e.which != 3;
		};
	}
	function noContextMenu($$) {
		return $$.each(function() {
			this.oncontextmenu = function() { return false; };
		});
	}

	fn.rightClick = function rightClick(callback) {
		return noContextMenu(this).mousedown(function() {
			$(this).one('mouseup', handler(callback, this));
		});
	};

	fn.rightMousedown = function rightMousedown(callback) {
		return noContextMenu(this).mousedown(handler(callback));
	};

	fn.rightMouseup = function rightMouseup(callback) {
		return noContextMenu(this).mouseup(handler(callback));
	};

})(jQuery.fn);
