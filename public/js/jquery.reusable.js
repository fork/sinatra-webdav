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
	// shows & hides children on hover
	$.fn.revealing = function() {
		return this.hover(
			function() { $('.hidden', this).show(); },
			function() { $('.hidden', this).hide(); }
		);
	};
	// add & removes .hover class of .hovers on hover
	$.fn.hovers = function() {
		return this.hover(
			function() { $('.hovers', this).addClass('hover'); },
			function() { $('.hovers', this).removeClass('hover'); }
		);
	};
	// blurs element on click
	$.fn.blurry = function() {
		return this.click(function() { $(this).blur(); });
	};
	// focus & selects selected elements
	//$.fn.selected = function() { return this.focus().select(); };

	$.fuzzy = {};
	$.fuzzy.defaults = {
//		input: 'input[type="text"]',
		filter: 'tr,li',
		hit: function(e) { e.style.display = 'table-row'; },
		miss: function(e) { e.style.display = 'none'; }
	};

/*
	$.fn.fuzzy = function(opts) {
		opts = $.extend({}, $.fuzzy.defaults, opts || {});
		var filter = this;

		$(options.input).keyup(function(e) {
			var term = this.value,
				exp = new RegExp(term.split('').join('.*'), 'i');

			filter.each(function() {
				var e = $(this);
				e.trigger(e.text().match(exp)? 'fuzzy.hit' : 'fuzzy.miss');
			});
		});

		return this.bind('fuzzy.hit', opts.hit).bind('fuzzy.miss', opts.miss);
	};
*/

	// converts value of input field into a regular expression an matches the
	// text value of filtered elements against it
	// by default and when the pattern does not match the text value the
	// filtered element is hidden
	$.fn.fuzzy = function(opts) {
		opts = $.extend({}, $.fuzzy.defaults, opts || {});

		return this.keydown(function(e) {
			if ($(this).hasClass('loader'))
				$(this).css({'background': 'url(/images/loader.gif) no-repeat right'});
		})
		.blur(function(e) {
			if ($(this).hasClass('loader')) $(this).css({'background': ''});
		})
		.keyup(function(e) {
			var term = this.value,
				exp = new RegExp(term.split('').join('.*'), 'i');

			$(opts.filter).each(function() {
				var text = $(this).text().replace(/\s+/g, ' ');
				opts[text.match(exp)? 'hit' : 'miss'](this);
			});
			if ($(this).hasClass('loader')) $(this).css({'background': ''});
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
				var cell = $(selector, row),
					span = cell.find('span.value'),
					value = span.length > 0 ? span.text() : cell.text();

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

	// apply on <input>s to submit form on keypress(keyCode:ENTER)
	// and dblclick on radiobuttons, checkboxes, textfields
	// or click on buttons or images
	$.fn.hurry = function(keyCode, callback) {
		var form = this.parent('form');

		if (typeof(keyCode) == 'function') {
			callback = keyCode;
			keyCode = undefined;
		}
		if (typeof(keyCode) == 'undefined') keyCode = 13;
		if (typeof(callback) == 'undefined') callback = function(e) {
			form.submit();
			e.preventDefault();
		};

		if ($('input[type="submit"]', form).length == 0)
			this.after('<input type="submit" style="display: none;" />');

		return this
		.each(function() {
			var self = $(this),
				t = self.attr('type'),
				e = ('button' == t || 'image' == t)? 'click' : 'dblclick';

			self.bind(e, callback);
		})
		.keypress(function(e) {
			if (keyCode == (e.keyCode || e.which)) callback.apply(this, [e]);
		});
	};

})(jQuery);
