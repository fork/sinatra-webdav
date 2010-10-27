jQuery(function($) {
	// var db = openDatabase('WebDAV Client', '1.0', 'WebDAV Client', 1024^2)
	// 
	// db.transaction(function(tx) {
	// 	tx.executeSql('CREATE TABLE IF NOT EXISTS bookmarks(id, name, url)');
	// });

	var $columns = $('#left, #right');

    $columns.bind('webdav.directory', function(event, href, data) {
		var $UL = $('.breadcrumb', this),
			$TABLE = $('.data table', this);

		console.log(href, data);
		console.log($TABLE);

		$UL.empty();

		$.cookie($(this).attr('id'), href);
		var path     = href.substr(href.indexOf('/', 8)),
		    dirnames = path.split('/'),
		    pattern  = dirnames.pop().replace(/\*/, '');

		dirnames.shift();
		$('<LI><A HREF="/*">/</A></LI>').prependTo($UL);

		$.each(dirnames, function(i) {
			var path = '/' + dirnames.slice(0, i + 1).join('/') + '/*',
				html = this + '/',
				$A = $('<A>').attr('href', path).html(html);

			$('<LI>').append($A).prependTo($UL);
		});
		$UL.children(':first-child').addClass('first');

		$('INPUT[name="pattern"]', this).val(pattern);

		$TABLE.html(data);
    }).each(function() {
		var id = $(this).attr('id'), href = $.cookie(id);
		if (href == null) href = location.href + '*';
		Controller('directory').apply(this, [href]);
	}).click(function(e) {
		var $$ = $(this), hasFocus = $$.is('.focus');
		if (!hasFocus) {
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

	$columns.find('.data').click(function(e) {
		e.preventDefault();

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
