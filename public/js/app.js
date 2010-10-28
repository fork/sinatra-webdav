jQuery(function($) {
	// var db = openDatabase('WebDAV Client', '1.0', 'WebDAV Client', 1024^2)
	// 
	// db.transaction(function(tx) {
	// 	tx.executeSql('CREATE TABLE IF NOT EXISTS bookmarks(id, name, url)');
	// });

	var $columns = $('#left, #right');
	var LI = '<LI>', A_button = '<A CLASS="button">';

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

    $columns.bind('webdav.directory', function(e, _, data) {
		$('.data tbody', this).html(data)
		.parent().sortableTable();
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
		var column = $columns.filter('.focus').get(0),
			key    = keygen(column, 'href'),
			href   = app(key).replace(/\*$/, ''),
			selected = $(column).find('tr.selected'),
			name = selected.length > 1 ? selected.length + ' items' :
			selected.first().find('td.name').text();
		
		if(!confirm('Do you really want to delete '+name+'?')) return;
		
		$.each(selected, function(i) {
			url = href + $(this).find('td.name').text();
			WebDAV.DELETE(url, function() {
				Controller('directory').apply(column, [app(key)]);
			});			
		});
	});
	$('a[name="logout"]').click(function(e) {
		var dirname = confirm('Do you really want to quit?');
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
});
