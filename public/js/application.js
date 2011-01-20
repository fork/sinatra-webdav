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
	var COLUMN = $('<TD>');
	function Column(html, type) {
		return COLUMN.clone().html(html).addClass(type);
	}
	var ROW = $('<TR>');
	function Row(type) {
		return ROW.clone().addClass(type);
	}

	function optionsForBreadcrumb(href) {
		var options  = [];
		var dirnames = href.split('/').slice(3);
		dirnames.pop();

		options.push(Option('/'));
		$.each(dirnames, function(i) {
			var path = '/' + dirnames.slice(0, i + 1).join('/') + '/';
			options.unshift(Option(this.toString() + '/', path));
		});

		return options;
	}
	function rowsForListing(resources) {
		var rows = [];

		$.each(resources, function() {
			var anchor = $('<A>').text(this.basename).attr('href', this.href);
			var row    = Row(this.contentType.split('/').join(' ')).
			append(
				Column(anchor, 'name'),
				//column.clone().text(bytesizeFormatter(this.contentLength)),
				Column(this.contentLength, 'size'),
				Column(this.contentType, 'type'),
				//column.clone().text(timeFormatter(this.lastModified))
				Column(this.lastModified.toString(), 'mtime')
			);
			if (this.basename.slice(0, 1) == '.') row.addClass('dotfile');

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
				optGroup.append(Option(type, type, true));
				type = types[group].shift();
			}
			optGroups.push(optGroup);
			group = groups.shift();
		}

		return optGroups;
	}

	function refresh(root, resources) {
		var select, tbody;

		tbody = this.find('.data tbody').empty();
		$.each(rowsForListing(resources), function() {
			tbody.append(this);
		});

		select = this.find('.typeSelect select').empty();
		$.each(optionsForTypeSelect(resources), function() {
			select.append(this);
		});

		breadcrumb = this.find('.breadcrumb').empty();
		$.each(optionsForBreadcrumb(root.href), function() {
			breadcrumb.append(this);
		});
	}

	$('.column').bind('expire', function(e) {
		var column    = $(this);
		var resources = column.data('resources');
		var root      = resources.shift();

		//resources.sort(this.data('sortByAttribute'));

		refresh.call(column, root, resources);
	});

	$('.breadcrumb').change(function() {
		var url = $(this).val();
		$.bbq.pushState({ url: url });
	});

	$('.typeSelect').click(function(e) {
		var $$ = $(this);
		if (e.target.tagName == 'OPTGROUP') {
			var values = [];

			$('option', e.target).each(function() {
				var option = $(this);
				values.push(option.attr('value') || option.text());
			});

			if (e.metaKey) {
				var selected_values = $$.find('select').val();
				var value = selected_values.pop();
				while (value) {
					var index = values.indexOf(value);

					if (index > -1) { values.splice(index, 1); }
					else { values.push(value); }

					value = selected_values.pop();
				}
			}

			$$.find('select').val(values);
		} else if (e.target.tagName != 'OPTION') {
			$(document).one('click', function() { $$.removeClass('active'); });
			$$.addClass('active');
			e.stopPropagation();
		}
	}).find('select').change(function() {
		var $$    = $(this);
		var tbody = $$.siblings('.data').find('tbody');

		tbody.children().removeClass('choosen');

		var types = $$.val();
		if (types === null) return;

		selector = $.map(types, function(v) { return '.' + v; }).join(', ');
		tbody.children(selector).addClass('choosen');
	});

	Controller['directory'] = function(url) {
		$.bbq.pushState({ url: url });
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

	var disabled = '<option disabled="disabled">Loading...</option>';
	$(window).bind('hashchange', function(e) {
		var column = $('.focus');
		var url = $.bbq.getState('url');

		column.find('.breadcrumb').html(disabled);

		WebDAV.PROPFIND(url, function(multistatus) {
			var resources = $('response', multistatus).map(WebDAV.Resource);
			resources.__proto__ = [];
			column.data('resources', resources).trigger('expire');
		});
	});

	$(window).trigger('hashchange');
});
