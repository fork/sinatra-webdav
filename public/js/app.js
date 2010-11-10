jQuery(function($) {
	// var db = openDatabase('WebDAV Client', '1.0', 'WebDAV Client', 1024^2)
	//
	// db.transaction(function(tx) {
	// 	tx.executeSql('CREATE TABLE IF NOT EXISTS bookmarks(id, name, url)');
	// });

	var $columns = $('#left, #right');
	var LI          = '<LI>',
		A_button    = '<A CLASS="button">';

	function hidden(html) {
		return $('<SPAN CLASS="hidden">').html(html);
	}
	function keygen(col, suffix) {
		return 'webdav.' + $(col).attr('id') + '.' + suffix;
	}
	function app(key, value) {
		if (arguments.length == 1) {
			return app.hasOwnProperty(key) ? app[key] : $.cookie(key);
		} else {
			$.cookie(key, value);
			return app[key] = value;
		}
	}

	function button(href, html) {
		return $(A_button).attr('href', href).html(html);
	}

	$columns.find('.data table').sorrow();
    $columns.bind('webdav.directory', function(e, _, data) {
		data.find('.type').each(function() {
			if (this.innerText == 'directory') {
				var SPAN = hidden('-1 ');
				$(this).siblings('.size').prepend(SPAN);
			}
		});
		data.find('.mtime').each(function() {
			var uts = new Date(this.innerText).valueOf(),
				SPAN = hidden(uts + ' ');

			$(this).prepend(SPAN);
		});

		rows = data.children('tr');
		$('.data table', this).sorrow('overwrite', { rows: rows });
		$('.data table', this).sorrow('sort');
	}).bind('webdav.directory', function(e, href) {
		var $UL = $('.breadcrumb', this), key = keygen(this, 'href');
		$UL.empty();

		app(key, href);
		var path     = href.substr(href.indexOf('/', 8)),
		    dirnames = path.split('/');

		dirnames.pop();
		dirnames.shift();

		$(LI).append(button('/*', '/')).prependTo($UL);
		$.each(dirnames, function(i) {
			var path = '/' + dirnames.slice(0, i + 1).join('/') + '/*';
			$(LI).append(button(path, this.toString())).prependTo($UL);
		});

		$UL.children(':first-child').addClass('first');
    }).data('index', 0).each(function() {
		var key = keygen(this, 'href'), href = app(key);
		if (href == null) href = location.href + '*';
		Controller('directory').apply(this, [href]);
	}).click(function(e) {
		var $$ = $(this), isFocused = $$.is('.focus');
		if (!isFocused) {
			$columns.removeClass('focus');
			$$.addClass('focus');
		}
	});

	$.breadcrumb = $('.breadcrumb');
	$.breadcrumb.click(function(e) {
		e.preventDefault();

		var $$ = $(this), isActive = $$.is('.active');
		if (isActive) {
			var TABLE = $(this).parent().find('.data').get(0);
			Controller('directory').apply(TABLE, [e.target.href]);
		} else {
			$$.addClass('active');
			e.stopPropagation();
		}
	});
	$(document).click(function(e) {
		var isActive = $.breadcrumb.is('.active');
		if (isActive) $.breadcrumb.removeClass('active');
	});

	$('a[name="mkdir"]').click(function(e) {
		e.preventDefault();

		var dirname = prompt('This directory takes it, you name it:');
		if (dirname == null) return;

		var column = $columns.filter('.focus').get(0),
			key    = keygen(column, 'href'),
			href   = app(key).replace(/\*$/, '');

		href += dirname;
		WebDAV.MKCOL(href, function() {
			Controller('directory').apply(column, [app(key)]);
		});
	});
	$('a[name="delete"]').click(function(e) {
		var $column  = $columns.filter('.focus'),
			key      = keygen($column, 'href'),
			href     = app(key).replace(/\*$/, ''),
			selected = $column.find('tr.selected'),
			question = 'Do you really want to delete ';

		if (selected.length > 1)
			question += 'selected resources';
		else
			question += selected.find('td.name').text();

		var sure = confirm( question + '?');
		if(!sure) return;

		$.each(selected, function(i) {
			var $TR = $(this), url = href + $TR.find('.name').text();
			WebDAV.DELETE(url, function() { $TR.remove(); });
		});
	});
	$('a[name="exit"]').click(function(e) {
		if(confirm('Do you really want to quit?')) window.location = '/logout';
	});

	$columns.find('.data').click(function(e) {
		e.preventDefault();

		$TR = $('TR', this).removeClass('selected').has(e.target);
		$TR.addClass('selected');

		var isAnchor = $(e.target).is('A');
		if (isAnchor) {
			var A    = e.target,
				$A   = $(A),
				type = $A.parents('TR').children('.type').text();

			if (type.length == 0) type = 'directory';

			Controller(type).apply(this, [A.href]);
		}
	});

	// TODO: Swap configuration to application configuration file
	$('.uploader').pluploadQueue({
		runtimes : 'html5',
		url : '/',
		max_file_size : '100mb',
		chunk_size : '1mb',
		unique_names : true,
		dragdrop : true
	});

});
