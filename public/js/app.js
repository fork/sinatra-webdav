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
	function getHost() {
		loc = window.location;
		port = loc.port == '' ? '' : ':' + loc.port;
		return loc.protocol + '//' + loc.host +	port;
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
			other_column = $columns.not('.focus'),
			key    = keygen(column, 'href'),
			href   = app(key).replace(/\*$/, ''),
			other_key    = keygen(other_column, 'href'),
			other_href   = app(other_key).replace(/\*$/, '');

		dirname = href + dirname;
		WebDAV.MKCOL(dirname, function() {
			Controller('directory').apply(column, [app(key)]);
			if (href == other_href)
				Controller('directory').apply(other_column, [app(key)]);
		});
	});
	$('a[name="copy"]').click(function(e) {
		e.preventDefault();

		var column = $columns.filter('.focus'),
			other_column = $columns.not('.focus'),
			selected = column.find('tr.selected'),
			target = other_column.find('tr.selected'),
		 	key    = keygen(column, 'href'),
		 	href   = app(key).replace(/\*$/, ''),
			host = getHost(),
			question = 'Do you really want to copy ',
			target_path, target_name, glob;

		if (target.length > 0) {
			glob = '/*';
			target_name = target.find('td.name').first().text();
			target_path = href + target_name;
		} else {
			glob = '*'
			target_name = other_column.find('li.first a').text();
			target_path = host + other_column.find('li.first a')
				.attr('href').replace(/\*$/, '');
		}

		if (selected.length > 1)
			question += 'selected resources';
		else
			question += selected.find('td.name').text();

		var sure = confirm( question + ' to ' + target_name + ' ?');
		if(!sure) return;

		$.each(selected, function(i) {
			var $TR = $(this), url = href + $TR.find('.name').text();
			WebDAV.COPY(url, target_path, function() {
				if (i + 1 == selected.length)
					Controller('directory').apply(other_column, [target_path + glob]);
			});
		});
	});
	$('a[name="move"]').click(function(e) {
		e.preventDefault();

		var column = $columns.filter('.focus'),
			other_column = $columns.not('.focus'),
			selected = column.find('tr.selected'),
			target = other_column.find('tr.selected'),
			target_name = target.find('td.name').first().text(),
		 	key    = keygen(column, 'href'),
		 	href   = app(key).replace(/\*$/, ''),
			host = getHost(),
			question = 'Do you really want to move ',
			target_path, target_name, glob, onlyRename = false;

		if (target.length > 0) {
			target_name = target.find('td.name').first().text();
			target_path = href + target_name;
			glob = target_path + '/*';
		} else {
			
			target_name = other_column.find('li.first a').text();
			target_path = host + other_column.find('li.first a')
				.attr('href').replace(/\*$/, '');
			glob = target_path + '*'
		}

		var rename;
		if (selected.length > 1) {
			question += 'selected resources';
			rename = confirm( question + ' to ' + target_name + ' ?');
		} else {
			var source_name = selected.find('td.name').text();
			question += source_name;
			rename = prompt( question + ' to ' + target_name + ' ?' +
				'\n Or enter different name to rename:', source_name);
		}

		if (rename == null) return;
		if (typeof(rename) == 'string' && rename != source_name) {
			onlyRename = true;
			target_path = href + rename;
		}

		$.each(selected, function(i) {
			var $TR = $(this), url = href + $TR.find('.name').text();
			WebDAV.MOVE(url, target_path, function() {
				if (i + 1 == selected.length) {
					Controller('directory').apply(column, [app(key)]);
					if (!onlyRename)
						Controller('directory').apply(other_column, [glob]);
				}
			});
		});
	});
	$('a[name="delete"]').click(function(e) {
		var $column  = $columns.filter('.focus'),
			other_column = $columns.not('.focus'),
			key      = keygen($column, 'href'),
			href     = app(key).replace(/\*$/, ''),
			other_key      = keygen(other_column, 'href'),
			other_href     = app(other_key).replace(/\*$/, ''),
			selected = $column.find('tr.selected'),
			question = 'Do you really want to delete ';

		if (selected.length > 1)
			question += 'selected resources';
		else
			question += selected.find('td.name').text();

		var sure = confirm( question + '?');
		if(!sure) return;

		$.each(selected, function(i) {
			var $TR = $(this), name = $TR.find('.name').text(),
				$OTHER_TR = other_column.find('td.name').filter(function() {
					return $(this).text() == name;
				}),
				url = href + name;
				if($OTHER_TR)
					console.log($OTHER_TR.length);
			WebDAV.DELETE(url, function() { 
				$TR.remove();
				if(href == other_href && $OTHER_TR.length != 0)
					$OTHER_TR.parent().remove();
			});
		});
	});
	$('a[name="exit"]').click(function(e) {
		if(confirm('Do you really want to quit?')) window.location = '/logout';
	});

	$columns.find('.data').click(function(e) {
		e.preventDefault();

		if (e.metaKey) {
			$TR = $('TR', this).has(e.target);
			$TR.toggleClass('selected');
		} else {
			$TR = $('TR', this).removeClass('selected').has(e.target);
			$TR.addClass('selected');
		}

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

	$('.plupload_filelist_toggle .icon').bind('mouseenter click', function() {
		$(this).parent().hide();
	  $(this).parent().siblings(".plupload_wrapper").show();
	});
	$('.plupload_filelist_header .icon').bind('mouseenter click', function() {
		$(this).parents('.plupload_wrapper').hide();
	  $(this).parents('.plupload_wrapper').siblings('.plupload_filelist_toggle').show();
	});
	$('.plupload_wrapper').hide();
	$('.plupload_filelist_toggle').show();

});
