jQuery(function($) {
	var OPTION = $('<option>');
	function Option(text, value) {
		var option = OPTION.clone();
		option.context = document;
		option.text(text).attr('value', value || text);
		return option;
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
		// sort resources
		return [];
	}
	function optionsForFilter(resources) {
		return [];
	}

	function refresh(resources) {
		var breadcrumb = this.find('.breadcrumb').empty();
		$.each(optionsForBreadcrumb(resources[0].href), function() {
			breadcrumb.append(this);
		});

		var tbody = this.find('.data tbody').empty();
		$.each(rowsForListing(resources), function() {
			tbody.append(this);
		});

		var filter = this.find('.filter').empty();
		$.each(optionsForFilter(resources), function() {
			filter.append(this);
		});
	}

	$('.column').bind('expire', function(e) {
		var column    = $(this);
		var resources = column.data('resources');

		refresh.call(column, resources);
	});

	$('.breadcrumb').change(function() {
		var url = $(this).val();
		$.bbq.pushState({ url: url });
	});

	var disabled = '<option disabled="disabled">Loading...</option>';
	$(window).bind("hashchange", function(e) {
		$('.focus .breadcrumb').html(disabled);

		var url = $.bbq.getState("url");
		WebDAV.PROPFIND(url, function(multistatus) {
			var resources = $('response', multistatus).map(Resource);
			$('.focus').data('resources', resources).trigger('expire');
		});
	});

	$(window).trigger("hashchange");
});
