(function($) {
	function Menu($$) {
		$$.data('menu', this);

		this.activate = function activate() {
			return $$.addClass('active').trigger('activate');
		};
		this.deactivate = function deactivate() {
			return $$.removeClass('active').trigger('deactivate');
		};

		return this;
	}

	$.fn['menu'] = function(handler) {
		var menu = this.data('menu');
		if (menu) { return menu; }

		return this.each(function() {
			var $$ = $(this);

			$$.click(function(e) {
				var et = $(e.target);

				$.each(handler, function(css) {
					if (et.is(css)) { this.call($$); }
				});
			});

			new Menu($$);
		});
	};

})(jQuery);
