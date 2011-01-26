(function(fn) {
	var $$ = $(document), handler;
	var mousedown = 'mousedown', mouseup = 'mouseup';

	function noMenu() { return false; }

	if ($.browser.mozilla) {
		handler = function handler(callback) {
			return function(e) {
				if (e.which === 3) { callback.call(this, e); }
			};
		};
	} else {
		handler = function handler(callback) {
			return function(e) {
				if (e.which === 3) { callback.call(this, e); }
				if (e.type === mousedown) { $$.one('contextmenu', noMenu); }
			};
		};
	}

	fn.rightClick = function rightClick(callback) {
		return this.rightMousedown(function() {
			$(this).one(mouseup, handler(callback));
		});
	};

	fn.rightMousedown = function rightMousedown(callback) {
		return this[mousedown](handler(callback));
	};

	fn.rightMouseup = function rightMouseup(callback) {
		return this[mouseup](handler(callback));
	};

})(jQuery.fn);
