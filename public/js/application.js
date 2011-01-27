jQuery(function($) {
	var OPTION = $('<option>');
	function Option(text, value, selected) {
		var option = OPTION.clone();
		option.context = document;
		option.text(text).attr('value', value || text);
		if (selected) { option.attr('selected', 'selected'); }
		return option;
	}
	var OPTGROUP = $('<optgroup>');
	function OptGroup(label) {
		var optGroup = OPTGROUP.clone();
		optGroup.context = document;
		optGroup.attr('label', label);
		return optGroup;
	}
	var COLUMN = $('<td>');
	function Column(html, type) {
		return COLUMN.clone().html(html).addClass(type);
	}
	var ROW = $('<tr>');
	function Row(type) {
		return ROW.clone().addClass(type);
	}

	function optionsForBreadcrumb(resource) {
		var resources = [resource].concat(resource.ancestors());
		return $.map(resources, function(r) {
			return Option(r.displayName + '/', r.href);
		});
	}
	var bytesizeFormatter = utils.Formatter.SI('B');
	function timeFormatter(date) {
		return utils.relativeTime.call(date, 100);
	}
	function rowsForListing(resources) {
		var rows = [];

		$.each(resources, function() {
			var anchor = $('<A>').
			             text(this.displayName).
			             attr('href', this.href);
			var types  = this.contentType.
			             replace(/\./g, '-').split('/').join(' ');
			var row    = Row(types).append(
				Column(anchor, 'name'),
				Column(timeFormatter(this.lastModified), 'mtime'),
				Column(bytesizeFormatter(this.contentLength), 'size'),
				Column(this.contentType.split('/')[0], 'type')
			);
			if (this.displayName.slice(0, 1) == '.') row.addClass('dotfile');

			rows.push(row);
		});

		return rows;
	}
	function optionsForTypeSelect(resources) {
		var types = {}, groups = [], optGroups = [];

		// make them unique
		$.each(resources, function() {
			var props = this.contentType.split('/');
			var group = props[0];
			var both  = props.join(' ');
			if (!types.hasOwnProperty(group)) {
				groups.push(group);
				types[group] = [ props[1] ];
			}
			if (types[group].indexOf(props[1]) < 0) {
				types[group].push(props[1]);
			}
		});

		groups.sort();
		var group = groups.shift();

		// render list items
		while (typeof group === 'string') {
			var optGroup = OptGroup(group).clone();
			types[group].sort();
			var type = types[group].shift();
			while (typeof type === 'string') {
				optGroup.append(Option(type, type.replace(/\./g, '-'), true));
				type = types[group].shift();
			}
			optGroups.push(optGroup);
			group = groups.shift();
		}

		return optGroups;
	}

	function refresh(root, resources) {
		var select, tbody;

		select = this.find('.typeSelect select').empty();
		$.each(optionsForTypeSelect(resources), function() {
			select.append(this);
		});
		select.change();

		breadcrumb = this.find('.breadcrumb').empty();
		$.each(optionsForBreadcrumb(root), function() {
			breadcrumb.append(this);
		});
	}

	$('.breadcrumb').change(function() {
		$(this).parents('.column').click();
		var url = $(this).val();
		$.bbq.pushState({ url: url });
	});

	var columns = $('.column').
	each(function() {
		var sorter    = utils.Sorter('displayName');
		var resources = [];
		var root;

		var column = $(this).
		bind('sort', function() {
			resources.sort(sorter);
			
			tbody = column.find('tbody').empty();
			$.each(rowsForListing(resources), function() {
				tbody.append(this);
			});
		}).
		bind('expire', function(e) {
			resources = column.data('resources');
			root      = resources.shift();

			column.trigger('sort');

			refresh.call(column, root, resources);
		}).
		click(function() {
			var focused = column.is('.focus');
			if (!focused) {
				columns.removeClass('focus');
				column.addClass('focus');
			}
		});

		var anchors = column.find('th a');
		column.find('th').
		click(function(e) {
			var anchor = (e.target.tagName === 'a') ?
			            $(e.target) : $('a', this);
			var property = anchor.attr('href').slice(1);

			anchors.removeClass('ascending descending');

			if (sorter.property == property) {
				sorter.reverse();
				anchor.addClass('descending');
			} else {
				sorter.ascending();
				sorter.property = property;
				anchor.addClass('ascending');
			}

			column.trigger('sort');
			e.preventDefault();
		}).
		mousedown(function(e) { e.preventDefault(); });

		var tbody = column.find('tbody').
		click(function(e) {
			e.preventDefault();

			var rows     = tbody.children('tr');
			var row      = rows.has(e.target);
			var index    = rows.index(row);
			var selected = row.hasClass('selected');

			if (e.metaKey) {
				row.toggleClass('selected');
			} else {
				if (e.shiftKey) {
					var prev      = row.prevAll('.selected:first');
					var next      = row.nextAll('.selected:first');
					var nextDistance;
					var prevDistance;
					var $$;

					if (prev.length === 0 && next.length === 0) {
						if (index > rows.length / 2) {
							$$ = row.nextAll();
						} else {
							$$ = row.prevAll();
						}
					} else if (prev.length === 0) {
						nextDistance = rows.index(next) - index;
						$$ = next.prevAll(':lt(' + nextDistance + ')');
					} else if (next.length === 0) {
						prevDistance = index - rows.index(prev);
						$$ = prev.nextAll(':lt(' + prevDistance + ')');
					} else {
						nextDistance = rows.index(next) - index;
						prevDistance = index - rows.index(prev);

						if (nextDistance > prevDistance) {
							$$ = prev.nextAll(':lt(' + prevDistance + ')');
						} else {
							$$ = next.prevAll(':lt(' + nextDistance + ')');
						}
					}

					$$.addClass('selected');
				} else {
					rows.removeClass('selected');
					row.addClass('selected');
				}
			}

			var isAnchor = e.target.tagName === 'A';
			if (isAnchor && selected) {
				var type = resources[index].contentType;
				Controller(type).apply(column, [e.target.href]);
			}
		}).
		mousedown(function(e) {
			e.preventDefault();
		});

		var dataContainer = column.find('.data').
		click(function(e) {
			// support global deselect
			var tableClicked = $('table', this).has(e.target).length > 0;
			if (!tableClicked) { tbody.find('tr').removeClass('selected'); }
		}).
		rightClick(function(e) {
			var rows      = tbody.children().removeClass('active');
			var row       = rows.has(e.target);
			var selected  = rows.filter('.selected');
			var context   = [];

			if (selected.has(e.target).length > 0) {
				// selected are clicked
				selected.each(function() {
					var index = rows.index(this);
					context.push(resources[index]);
				}).addClass('active');
			} else if (row.length > 0) {
				// another resource was clicked
				var index = tbody.children().index(row);
				context.push(resources[index]);
				row.addClass('active');
			} else {
				// empty space was clicked
				context.push(root);
			}

			$('#context-menu').data({resources: context, column: column}).
			one('deactivate', function() {
				rows.removeClass('active');
				dataContainer.css('overflow-y', 'scroll');
			}).
			menu('activate');

			dataContainer.css('overflow-y', 'hidden');
		});
	});

	var position = { top: 0, left: 0 };
	$.menu = { position: position };

	$(document).mousemove(function(e) {
		position.top  = e.clientY;
		position.left = e.clientX;
	});

	function Menu($$) {
		var menu = this;

		$$.data('menu', menu);

		menu.deactivate = function deactivate() {
			$$.trigger('deactivate');
			$$.removeClass('active');
			return $$;
		};
		menu.activate = function activate() {
			$$.trigger('activate');
			// TODO set offset so nothing of context menu is hidden
			$$.css(position);
			$$.addClass('active');
			return $$;
		};

		$(document).click(function(e) {
			if (e.which !== 3) menu.deactivate();
		});

		return menu;
	}

	$.fn.menu = function menu(handler) {
		var $$   = this;
		var menu = $$.data('menu');

		if (typeof menu === 'undefined') {
			menu = new Menu($$);
		} else if (typeof handler === 'string') {
			return menu[handler]();
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
			if (!handling) {
				e.preventDefault();
				e.stopPropagation();
			}
		});
	};

	$('#context-menu').menu({
		'#get-resource': function() {
			var column = $(this).data('column');
			var resource = $(this).data('resources')[0];
			Controller(resource.contentType).apply(column, [resource.href]);
		},
		'#delete': function() {},
		'#copy': function() {},
		'#move': function() {},
		'#make-directory': function() {}, // root
		'#properties': function() {}, // single resource
		'#logout': function() {
			sure = confirm('Are you sure?');
			if (sure) location.href = '/auth/logout';
		}
	}).bind('activate', function() {
		var $$ = $(this);
		var resources = $$.data('resources');
		var title;

		if (resources.length === 1) {
			var resource = resources[0];

			if (resource.parent()) {
				title = resource.displayName;
			} else {
				title = '/';
			}

			$$.removeClass('resources');

			if (resource.isCollection()) {
				$$.addClass('collection');
			} else {
				$$.addClass('resource');
			}
		} else {
			$$.removeClass('collection resource');
			$$.addClass('resources');
			title = 'Resources';
		}

		$('h3 a', this).text(title);
		$('li:first:visible', this).bigtext({
			childSelector: '> h3',
			maxfontsize:   2.6
		});
	});

	$('.typeSelect').each(function() {
		var $$ = $(this);

		$(document).click(function() { $$.removeClass('active'); });

		var label = $$.find('label').
		click(function(e) {
			var active = $$.hasClass('active');
			if (active) return;

			$$.addClass('active');
			select.focus();

			e.stopPropagation();
		}).
		mousedown(function(e) { e.preventDefault(); });

		var select = $$.find('select').
		change(function() {
			var tbody = $$.parent().find('tbody'), selector;

			tbody.children().addClass('hidden');

			var types = select.val();
			if (types === null) return;

			selector = $.map(types, function(type) {
				return '.' + type;
			}).join(', ');
			tbody.children(selector).removeClass('hidden');

			if (tbody.children('.hidden').length > 0) {
				label.text('Showing: Some Files');
			} else {
				label.text('Showing: All Files');
			}
		}).
		click(function(e) {
			if (e.target.tagName === 'OPTGROUP') {
				var values = [];

				$('option', e.target).each(function() {
					var option = $(this);
					values.push(option.attr('value') || option.text());
				});

				if (e.metaKey) {
					var selectedValues = select.val();
					var value = selectedValues.pop();
					while (value) {
						var index = values.indexOf(value);

						if (index > -1) { values.splice(index, 1); }
						else { values.push(value); }

						value = selectedValues.pop();
					}
				}

				select.val(values);
				select.change();
			}
			e.stopPropagation();
		});
	});

	$('.expander').click(function(e) {
		var visible = $('#second').toggleClass('hidden').is(':visible');
		$('.column').toggleClass('half').filter(':visible:last').click();

		$('#container').toggleClass('single double');

		if (visible) {
			$(window).trigger('hashchange');
		}

		e.stopPropagation();
	});

	// Set controller actions
	Controller['directory'] = function(url) {
		$.bbq.pushState({ url: url });
	};
	Controller['application/octet-stream'] = function(url) {
		// we can apply pattern matching here
		// if (/.include$/.test(url)) ...

		window.open(url);
	};
	Controller['text/html'] = function(url) {
		var host = location.protocol + '//' + location.host;
		var path = url.replace(/https?:\/\//, '');
	
		window.location = 'http://vizard.fork.de/' + path + '?path=' + url +
		'&origin='      + host +
		'&return='      + location.href +
		'&handler='     + host + '/application/vizard/handler.js' +
		'&vizardcss='   + host + '/application/vizard/styles.css' +
		'&cktemplates=' + host + '/application/vizard/templates.js';
	};

	// Load resources on hashchange
	var disabled = '<option disabled="disabled">Loading...</option>';
	$(window).bind('hashchange', function(e) {
		var column = $('.focus');
		var url = $.bbq.getState('url');

		column.find('.breadcrumb').html(disabled);

		WebDAV.PROPFIND(url, function(multistatus) {
			var resources = [];
			$('response', multistatus).each(function() {
				var resource = new WebDAV.Resource(this);
				resources.push(resource);
			});
			column.data('resources', resources).trigger('expire');
		});
	});

	var log = $('#log').
	ajaxSend(function(e, xhr, opts) {
		var text = '';
		text += new Date().valueOf();
		text += [':', opts.type, opts.url].join(' ');

		var line = $('<div>').addClass(opts.type.toLowerCase()).html(text);
		log.prepend(line);
	}).
	dblclick(function() {
		log.toggleClass('minimized');
	}).
	mousedown(function(e) { e.preventDefault(); });

	$(window).trigger('hashchange');
});
