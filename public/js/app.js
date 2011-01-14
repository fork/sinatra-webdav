jQuery(function($) {

	function pad(str, padString, length) {
		str += '';
		while (str.length < length) str = padString + str;
		return str;
	}

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
		return location.protocol + '//' + location.host;
	}

	// http://dense13.com/blog/2009/05/03/converting-string-to-slug-javascript/
	function generateSlug(str) {
	  str = str.replace(/^\s+|\s+$/g, ''); // trim
	  str = str.toLowerCase();

	  // remove accents, swap ñ for n, etc
	  var from = "àáäâèéëêìíïîòóöôùúüûñç·/_,:;";
	  var to   = "aaaaeeeeiiiioooouuuunc------";
	  for (var i=0, l=from.length ; i<l ; i++) {
	    str = str.replace(new RegExp(from.charAt(i), 'g'), to.charAt(i));
	  }

	  str = str.replace(/[^a-z0-9 -]/g, '') // remove invalid chars
	    .replace(/\s+/g, '-') // collapse whitespace and replace by -
	    .replace(/-+/g, '-'); // collapse dashes

	  return str;
	}

	var trailing_slash = /\/$/;

	function mkcolRecursive(paths_array, callback) {
		var a = paths_array,
			path = a.shift();

		if (typeof path === 'undefined') callback();
		else {
			if (!trailing_slash.test(path)) path += '/';

			$.ajax({
				type: 'MKCOL', url: path,
				complete: function() { mkcolRecursive(a, callback); }
			});
		}
	}

	function button(href, html) {
		return $(A_button).attr('href', href).html(html);
	}

	var ROW = $('<TR><TD CLASS="name"><A></A></TD><TD CLASS="size"></TD><TD CLASS="type"></TD><TD CLASS="mtime"></TD></TR>');

	$columns.find('.data table').sorrow();
//    $columns.bind('webdav.directory', function(e, _, data) {
    $columns.bind('webdav.directory', function(e) {
		var resources = $(this).data('resources'), rows = $();

		$.each(resources, function() {
			if (/(^\.|\.include$)/.test(this.basename)) return;
			if (this.basename === 'application') return;

			var isCollection = /\/$/.test(this.href);
			var row = ROW.clone(), resource = this;

			row.find('.name a').attr('href', this.href).text(this.basename);

			var typeValue = isCollection ? 'directory' : this.contentType;
			row.find('.type').text(typeValue);

			var size = row.find('.size').append(this.contentLength);
			if (isCollection) size.prepend(hidden('-1'));

			var value = this.lastModified;
			row.find('.mtime').append(hidden(value.valueOf() + ' '), value.toLocaleString());

			rows = rows.add(row);
		});

		$('.data table', this).sorrow('overwrite', { rows: rows });
		$('.data table', this).sorrow('sort');
	}).bind('webdav.directory', function(e) {
		var href = $(this).data('href');
		var $UL = $('.breadcrumb', this), key = keygen(this, 'href');
		$UL.empty();

		app(key, href);
		var path     = '/' + href.split('/').slice(3).join('/'),
		    dirnames = path.split('/');

		dirnames.pop();
		dirnames.shift();

//		$(LI).append(button('/*', '/')).prependTo($UL);
		$(LI).append(button('/', '/')).prependTo($UL);
		$.each(dirnames, function(i) {
//			var path = '/' + dirnames.slice(0, i + 1).join('/') + '/*';
			var path = '/' + dirnames.slice(0, i + 1).join('/') + '/';
			$(LI).append(button(path, this.toString())).prependTo($UL);
		});

		$UL.children(':first-child').addClass('first');
    }).data('index', 0).each(function() {
		var key = keygen(this, 'href'), href = app(key);
		if (href == null) href = location.href;
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
			var column = $(this).parents('.column').get(0);
			Controller('directory').apply(column, [e.target.href]);
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

		if (!(/\/$/).test(dirname)) dirname += '/';

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

	// FIXME copy and move are the same except the VERB
	$('a[name="copy"]').click(function(e) {
		e.preventDefault();

		var sourceColumn = $columns.filter('.focus'),
		    resources    = sourceColumn.find('.selected'),
		    countdown    = length = resources.length;

		if (length == 0) return;

		var destination;

		var targetColumn = $columns.not('.focus'),
		    targetBase   = targetColumn.data('href'),
		    targetHost   = targetBase.split('/').slice(0, 3).join('/'),
		    targetDir    = '/' + targetBase.split('/').slice(3).join('/'),
		    sourceBase   = sourceColumn.data('href');

		if (length == 1) {
			destination = targetDir + resources.find('.name a').text();
			destination = prompt('Copy file to:', destination);
			if (!destination) return;

			if (destination.slice(0, 1) != '/') {
				destination = sourceBase + destination;
			} else {
				destination = targetHost + destination;
			}

			targetBase = destination.split('/');
			targetBase.pop();
			targetBase = targetBase.join('/') + '/';

			var source = resources.find('.name a'),
			    uri = source.attr('href');

			if (/\/$/.test(uri)) destination += '/';

			WebDAV.COPY(uri, destination, function() {
				Controller('directory').call(targetColumn, targetBase);
				Controller('directory').call(sourceColumn, sourceBase);
			});
		} else {
			targetDir = prompt('Copy files to:', targetDir);
			if (!targetDir) return;

			if (targetDir.slice(0, 1) != '/') {
				targetBase = sourceBase + targetDir;
			}

			resources.each(function() {
				var source = $('.name a', this), uri = source.attr('href');

				destination = targetBase + source.text();
				if (/\/$/.test(uri)) destination += '/';

				WebDAV.COPY(uri, destination, function() {
					if (--countdown > 0) return;
					Controller('directory').call(targetColumn, targetBase);
					Controller('directory').call(sourceColumn, sourceBase);
				});
			});
		}
	});
	$('a[name="move"]').click(function(e) {
		e.preventDefault();

		var sourceColumn = $columns.filter('.focus'),
		    resources    = sourceColumn.find('.selected'),
		    countdown    = length = resources.length;

		if (length == 0) return;

		var destination;

		var targetColumn = $columns.not('.focus'),
		    targetBase   = targetColumn.data('href'),
		    targetHost   = targetBase.split('/').slice(0, 3).join('/'),
		    targetDir    = '/' + targetBase.split('/').slice(3).join('/'),
		    sourceBase   = sourceColumn.data('href');

		if (length == 1) {
			destination = targetDir + resources.find('.name a').text();
			destination = prompt('Move file to:', destination);
			if (!destination) return;

			if (destination.slice(0, 1) != '/') {
				destination = sourceBase + destination;
			} else {
				destination = targetHost + destination;
			}

			targetBase = destination.split('/');
			targetBase.pop();
			targetBase = targetBase.join('/') + '/';

			var source = resources.find('.name a'),
			    uri = source.attr('href');

			if (/\/$/.test(uri)) destination += '/';

			WebDAV.MOVE(uri, destination, function() {
				Controller('directory').call(targetColumn, targetBase);
				Controller('directory').call(sourceColumn, sourceBase);
			});
		} else {
			targetDir = prompt('Move files to:', targetDir);
			if (!targetDir) return;

			if (targetDir.slice(0, 1) != '/') {
				targetBase = sourceBase + targetDir;
			}

			resources.each(function() {
				var source = $('.name a', this), uri = source.attr('href');

				destination = targetBase + source.text();
				if (/\/$/.test(uri)) destination += '/';

				WebDAV.MOVE(uri, destination, function() {
					if (--countdown > 0) return;
					Controller('directory').call(targetColumn, targetBase);
					Controller('directory').call(sourceColumn, sourceBase);
				});
			});
		}
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
				url = $TR.find('.name a').attr('href');
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

		var wasSelected = $(e.target).is('A') && $(e.target).parent().parent()
			.hasClass('selected');

		if (e.metaKey) {
			$TR = $('TR', this).has(e.target);
			$TR.toggleClass('selected');
		} else {
			$TR = $('TR', this).removeClass('selected').has(e.target);
			$TR.addClass('selected');
		}

		var isAnchor = $(e.target).is('A');
		if (isAnchor && wasSelected) {
			var A    = e.target,
				$A   = $(A),
				type = $A.parents('TR').children('.type').text(),
				column = $(this).parents('.column').get(0);

			if (type.length == 0) type = 'directory';

			Controller(type).apply(column, [A.href]);
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
