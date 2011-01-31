(function($) {
	function Menu($$) {

		this.deactivate = function deactivate() {
			$$.removeClass('active');
			$$.trigger('deactivate');
			return $$;
		};

		this.activate = function activate() {
			$$.addClass('active');
			$$.trigger('activate');
			return $$;
		};

		$$.data('menu', this);

		return this;
	}

	$.fn.menu = function menu(handler) {
		var $$   = this;
		var menu = $$.data('menu');

		if (typeof menu === 'undefined') {
			menu = new Menu($$);
		} else {
			return menu;
		}

		return this.click(function(e) {
			var self = this;
			var handling;
			$.each(handler, function(selector) {
				handling = $(e.target).is(selector);
				if (handling) this.call(self);
				return !handling;
			});
		});
	};

})(jQuery);
