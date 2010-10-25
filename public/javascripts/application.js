jQuery(function($) {
	// var db = openDatabase('WebDAV Client', '1.0', 'WebDAV Client', 1024^2)
	// 
	// db.transaction(function(tx) {
	// 	tx.executeSql('CREATE TABLE IF NOT EXISTS bookmarks(id, name, url)');
	// });

	var $columns = $('#left, #right');

    $columns.bind('webdav.directory', function(event, href, TBODY) {
		var $SELECT = $('SELECT[name="dirname"]', this),
			$TABLE = $('TABLE', this);

		$SELECT.empty();
		$TABLE.empty();

		$.cookie($(this).attr('id'), href);
		var path     = href.substr(href.indexOf('/', 8)),
		    dirnames = path.split('/'),
		    pattern  = dirnames.pop().replace(/\*/, '');

		$.each(dirnames, function(i) {
			var path = dirnames.slice(0, i).join('/') + '/', html = this + '/';
			$('<OPTION>').val(path).html(html).prependTo($SELECT);
		});
		$('INPUT[name="pattern"]', this).val(pattern);

		$TABLE.html(TBODY);
    }).each(function() {
		var id = $(this).attr('id'), href = $.cookie(id);
		if (href == null) href = location.href + '*';
		Controller('directory').apply(this, [href]);
	}).submit(function(e) {
		e.preventDefault();

		var href = location.href;
		var pattern = $('INPUT[name="pattern"]', this).val();
		if (pattern.length == 0) pattern = '*';

		href += $('SELECT[name="dirname"]', this).val();
		href += pattern;

		Controller('directory').apply(this, [href]);
	}).change(function(e) {
		$(e.target).parent().submit();
	});

	$columns.children('TABLE').click(function(e) {
		e.preventDefault();

		var isAnchor = $(e.target).is('A');
		if (isAnchor) {
			var A    = e.target,
				$A   = $(A),
				type = $A.parents('TR').children('.type').text();

			Controller(type).apply(this, [A.href]);
		}
	});
});
