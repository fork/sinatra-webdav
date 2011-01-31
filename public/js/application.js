jQuery(function($) {
	var win = $(window), doc = $(document);

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
			var abbr = this.displayName;
			if (abbr.length > 60) {
				var lastDot = abbr.lastIndexOf('.');
				abbr = abbr.slice(0, 60) + ' ... ' + abbr.slice(lastDot);
			}
			var anchor = $('<A>').text(abbr).
			             attr({href: this.href, title: this.displayName});
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
		bind('redraw', function() {
			tbody = column.find('tbody').empty();
			$.each(rowsForListing(resources), function() {
				tbody.append(this);
			});
		}).
		bind('sort', function() {
			resources.sort(sorter);
			column.trigger('redraw');
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

			var rows     = tbody.children();
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
		}).
		dblclick(function(e) {
			var isAnchor = e.target.tagName === 'A';
			if (isAnchor) { 
				var rows     = tbody.children();
				var row      = rows.has(e.target);
				var index    = rows.index(row);
				var type     = resources[index].contentType;

				Controller(type).apply(column, [e.target.href]);
			}
		}).
		mousedown(function(e) {
			e.preventDefault();
		});

		column.find('.data').
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

			var position = fixPosition({ top: e.clientY, left: e.clientX });

			menu.data({resources: context, column: column}).
			one('activate', function() { menu.css(position); }).
			one('deactivate', function() { rows.removeClass('active'); }).
			menu().activate();
		});
	});

	// moves menu to another position if it'd overflow the window limits
	function fixPosition(position) {
		var width = menu.outerWidth();
		var winWidth = win.width();
		if (winWidth < position.left + width) { position.left -= width; }

		var height = menu.outerHeight();
		var winHeight = win.height();
		if (winHeight < position.top + height) { position.top -= height; }

		return position;
	}

	var menu = $('#context-menu').menu({
		'#get-resource': function() {
			var column = menu.data('column');
			var resource = menu.data('resources')[0];
			// RADAR just GET the resource.href for multiple resources in
			//       seperate windows?
			// var resources = $(this).data('resources');
			// $.each(resources, function() { window.open(this.href); });
			Controller(resource.contentType).apply(column, [resource.href]);
		},
		'#delete': function() {
			var column    = menu.data('column');
			var resources = menu.data('resources');
			var count     = resources.length;
			var all       = column.data('resources');

			var sure = confirm('Really delete resource(s)?');
			if (!sure) return;

			$.each(resources, function() {
				var resource = this;
				this.del(function() {
					var index = all.indexOf(resource);
					all.splice(index, 1);
					column.trigger('redraw');
					if (--count !== 0) { return; }
					alert('Resource(s) deleted.');
				});
			});
		},
		'#duplicate': function() {
			var column    = menu.data('column');
			var resources = menu.data('resources');
			var all       = column.data('resources');

			var allNames  = [];
			for (var i = 0; i < all.length; i++) {
				allNames.push(all[i].displayName);
			}

			$.each(resources, function() {
				var resource    = this;
				var href        = decodeURIComponent(resource.parent().href);
				var displayName = basename = resource.displayName + ' Copy';
				var index       = 0;
				while (allNames.indexOf(displayName) !== -1) {
					index++;
					displayName = basename + ' ' + index;
				}
				href += displayName;
				if (resource.isCollection()) { href += '/'; }

				var duplicate = $.extend({}, resource, {
					displayName: displayName,
					href: href,
					lastModified: new Date()
				});

				this.copy(duplicate.href, function() {
					all.push(duplicate);
					column.trigger('sort');
				}, 1 / 0, false);
			});
		},
		'#copy': function() {
			
		},
		'#move': function() {},
		'#rename': function() {
			var column   = menu.data('column');
			var resource = menu.data('resources')[0];
			var all      = column.data('resources');

			var displayName = prompt('Enter new filename:', resource.displayName);

			if (displayName) {
				var href = decodeURIComponent(resource.parent().href);
				href += displayName;
				if (resource.isCollection()) { href += '/'; }

				var destination = $.extend({}, resource, {
					displayName: displayName,
					href: href,
					lastModified: new Date()
				});

				resource.move(destination.href, function() {
					var index = all.indexOf(resource);
					all[index] = destination;
					column.trigger('sort');
				}, 1 / 0, false);
			}
		},
		'#get-info': function() {
			// emit PROPFINDs
		}
		//'#make-directory': function() {},
		//'#logout': function() {
		//	sure = confirm('Are you sure?');
		//	if (sure) location.href = '/auth/logout';
		//}
	}).bind('activate', function() {
		var resources = menu.data('resources');
		var singular  = resources.length === 1;

		menu.removeClass('resources resource');

		if (singular) {
			menu.addClass('resource');
			clipboard.zeroclipboard({text: resources[0].path()});
		}
		else {
			menu.addClass('resources');
		}
	});

	doc.click(function(e) {
		if (e.which !== 3) menu.menu().deactivate();
	});

	$.extend(ZeroClipboard, {
		moviepath: '/js/zeroclipboard/zeroclipboard.swf'
	});
	var clipboard = $('#clipboard').zeroclipboard({ hand: true }).
	mouseover(function() { clipboard.addClass('hover'); }).
	mouseout(function() { clipboard.removeClass('hover'); });

	$('.typeSelect').each(function() {
		var $$ = $(this);

		doc.click(function() { $$.removeClass('active'); });

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

				// metaKey on OS X
				// TODO ctrlKey on Windows and Linux
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
			win.trigger('hashchange');
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
		var path = url.slice(host.length);

		window.location = 'http://vizard.fork.de/' + path + '?path=' + url +
		'&origin='      + host +
		'&return='      + location.href +
		'&handler='     + host + '/application/vizard/handler.js' +
		'&vizardcss='   + host + '/application/vizard/styles.css' +
		'&cktemplates=' + host + '/application/vizard/templates.js';
	};

	// Load resources on hashchange
	var disabled = '<option disabled="disabled">Loading...</option>';
	win.bind('hashchange', function(e) {
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

	win.trigger('hashchange');
});
