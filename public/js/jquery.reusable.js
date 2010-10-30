// NOTICE: ALWAYS RETURN THE JQUERY!

(function($) {
	'use strict';

	// apply to <a>nchors, forces browser to open href in a new window
	$.fn.blank = function() {
		return this.click(function(e) {
			window.open(this.href);
			e.preventDefault();
		});
	};

	// sorts a table by clicking on table head columns
	$.fn.sortableTable = function(opts) {
		var tbody = $(this).find('tbody'), tr = tbody.find('tr'),
			thead = $(this).find('thead'), th = thead.find('th');
		opts = opts || {};

		return th.click(function(e) {
			var column = $(this), siblings = column.siblings(),
				offset = opts.offset ? opts.offset : 0,
				selector = 'td:eq(' + (th.index(column) + offset) + ')',
				reverse = column.hasClass('asc'), sorted;

			sorted = _.sortBy(tr.detach(), function(row) {
				var value = $(selector, row).text();

				return value.match(/^\d+$/) ?
					value * 1 : value.toLowerCase();
			});

			siblings.removeClass('desc asc');

			if (reverse) {
				column.removeClass('asc').addClass('desc');
				tbody.html(sorted.reverse());
			} else {
				column.removeClass('desc').addClass('asc');
				tbody.html(sorted);
			}
		});
	};

})(jQuery);
