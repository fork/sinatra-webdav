(function($) {

	var slice   = Array.prototype.slice,
		concat  = Array.prototype.concat,
		methods = {};

	methods.sort = function(table) {
		var column     = table.find('.asc, .desc'),
			data       = table.data('sorrow'),
			index      = $('th', table).index(column) + data.offset,
			descending = column.hasClass('desc'),
			selector   = 'td:eq(' + index + ')',
			rows       = _.sortBy(data.rows, function(row) {
				var values = $(selector, row).text().split(' ');
				return _.map(values, function(v) {
					return v.match(/^-?[\d\.]+$/) ? v * 1 : v.toLowerCase();
				});
			});

		table.find('tbody').html(descending ? rows.reverse() : rows);
	};
	methods.overwrite = function(table, data) {
		return $.extend(table.data('sorrow'), data);
	};

	// sorts a table by clicking on table head columns
	$.fn.sorrow = function(opts) {
		if (typeof(arguments[0]) == 'string') {
			var name = arguments[0], table, args;

			// recast without selector
			table = $(this.get(0));
			// convert arguments into array and read from 2nd element
			args = slice.apply(arguments, [1]);
			//  prepend recast table
			args = concat.apply([ table ], args);

			return methods[name].apply(window, args);
		} else {
			if (typeof(arguments[0]) == 'undefined') opts = {};
			if (typeof(opts.offset) != 'number') opts.offset = 0;

			return this.each(function() {
				var table = $(this);

				table.data('sorrow', {
					offset: opts.offset,
					rows: table.find('tbody tr').find('tr')
				});

				table.find('th').click(function(e) {
					e.preventDefault();

					var column     = $(this),
						ascending  = column.hasClass('asc'),
						descending = column.hasClass('desc');

					if (ascending) {
						column.removeClass('asc').addClass('desc');
					} else if (descending) {
						column.removeClass('desc').addClass('asc');
					} else {
						column.siblings().removeClass('asc desc');
						column.addClass('asc');
					}

					methods.sort(table);
				});
			});
		}
	};

})(jQuery);
