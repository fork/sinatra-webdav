(function(fn) {

	fn.rightClick = function rightClick(handler) {
		return this.noContext().
		mousedown(function(e) {
			var context = this;

			$(this).one('mouseup', function() {
				if (e.which == 3) { handler.call(context, e); }
				return e.which != 3;
			});
		});
	};

	fn.rightMousedown = function rightMousedown(handler) {
		return this.noContext().
		mousedown(function(e) {
			if (e.which == 3) { handler.call(this, e); }
			return e.which != 3;
		});
	};

	fn.rightMouseup = function rightMouseup(handler) {
		return this.noContext().
		mouseup(function(e) {
			if (e.which == 3) { handler.call(this, e); }
			return e.which != 3;
		});
	};

	fn.noContext = function noContext() {
		return this.each(function() {
			this.oncontextmenu = function() { return false; };
		});
	};

})(jQuery.fn);
