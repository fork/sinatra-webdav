(function($) {
	var zeroclipboard = 'zeroclipboard';
	var load          = 'load';
	var mouseover     = 'mouseover';
	var mouseout      = 'mouseout';
	var mousedown     = 'mousedown';
	var mouseup       = 'mouseup';
	
	var ZeroClipboard = {
		moviepath: 'ZeroClipboard.swf',
		// clients maps the SWF id back to the original element
		clients: {},
		dispatch: function (id, eventName, args) {
			var $$   = $(this.clients[id]);
			var data = $$.data(zeroclipboard);

			//console.log('Dispatch: ' + eventName);
			eventName = eventName.toString().toLowerCase();

			if (eventName === load) {
				// bug fix: Cannot extend EMBED DOM elements in Firefox, must
				// use traditional function
				var movie = document.getElementById(zeroclipboard + '_swf_' + id);
				// movie claims it is ready, but in IE this isn't always the
				// case...
				if (!movie) {
					setTimeout(function() {
						ZeroClipboard.dispatch(id, load);
					}, 1);
					return;
				}

				// firefox on pc needs a "kick" in order to set these in
				// certain cases
				if (!data.ready && jQuery.browser.mozilla) {
					data.ready = true;
					setTimeout(function() {
						ZeroClipboard.dispatch(id, load);
					}, 100);
					return;
				}

				data.ready = true;
				ZeroClipboard.update(id);
			} else if (eventName === mouseover) {
				$$.trigger(mouseover);
			} else if (eventName === mouseout) {
				$$.trigger(mouseout);
				// This is to cover up the bug of dragging the mouse out
				// of the flash (mainly used when reseting css).
				if (data.downfix) { $$.trigger(mouseup); }
			} else if (eventName === mouseup) {
				$$.trigger(mouseup);
				data.downfix = false;
			} else if (eventName === mousedown) {
				data.downfix = true;
				$$.trigger(mousedown);
			} else if (eventName === 'complete') {
				$$.trigger('click');
			}
		},
		update: function (id) {
			// Take the ID, and find the main div.
			var $$ = $(this.clients[id]);
			var data = $$.data(zeroclipboard) || {};

			var flash = document.getElementById(zeroclipboard + '_swf_' + id);
			var fla$h = $(flash);

			if (data.resize) {
				// Get all the details
				var outerWidth  = $$.outerWidth();
				var outerHeight = $$.outerHeight();
				var css        = $.extend($$.offset(), {
					height: outerHeight,
					width:  outerWidth
				});

				fla$h.attr({ width: outerWidth, height: outerHeight }).
				parent().css(css);

				data.resize = false;
			}

			if (data.ready) {
				//console.log("[update] text = " + data.text);
				flash.setText(data.text);
				flash.setHandCursor(data.hand);
			} else {
				//console.log("[update] skipping...");
			}
		}
	};

	this.ZeroClipboard = ZeroClipboard;

	// RADAR this is done later this script again... don't like this hack!
	// Code borrowed from
	// http://stackoverflow.com/questions/2200494/jquery-trigger-event-when-an-element-is-removed-from-the-dom
	var removeEvent = new $.Event('remove');
	var __remove = $.fn.remove;
	$.fn.remove = function() {
		this.trigger(removeEvent);
		__remove.apply(this, arguments);
	};

	// Setup window resize event.
	$(window).resize(function () {
		$.each(ZeroClipboard.clients, function(id) {
			$(this).data(zeroclipboard).resize = true;
			ZeroClipboard.update(id);
		});
	});

	// Run the window resize anytime an element is removed
	$('*').bind('remove', function () { $(window).resize(); });

	function generateId(options) {
		options = $.extend({
			'chars':  'ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz',
			'length': 8
		}, options);

		var chars = options.chars;
		var alpha = chars.match(/[a-z]/gi);
		var limit = options.length - 1;
		var retrn, rnum;

		do {
			rnum  = Math.floor(Math.random() * alpha.length);
			retrn = alpha[rnum];

			for (var i = 0; i < limit; i++) {
				rnum   = Math.floor(Math.random() * chars.length);
				retrn += chars.substring(rnum, rnum + 1);
			}
		} while (document.getElementById(retrn) !== null);

		return retrn;
	}

	$.fn.zeroclipboard = function (options) {
		options = options || {};

		return this.each(function() {
			var $$   = $(this);
			var data = $$.data(zeroclipboard) || {};
			var clipboard_id = zeroclipboard + '_swf_' + data.id;
			
			if (data.id) { // modify existing zeroClipBoard
				if (options.destroy) {
					// console.log("Removing client #" + data.id);
					// We have a request to destroy the flash, and it appears
					// we have made the flash object already.
					$('#' + clipboard_id).parent().remove();
					delete ZeroClipboard.clients[data.id];
				} else {
					if (options.text) {
						//console.log('[' + data.id + '] Text: ' + options.text);
						data.text = options.text;
					}
					if (options.hand) {
						//console.log('[' + data.id + '] Hand: ' + options.hand);
						data.hand = options.hand;
					}

					// while I'm here...
					data.resize = true;

					ZeroClipboard.update(data.id);
				}
			} else { // initialize new zeroClipBoard
				$$.data(zeroclipboard, data);

				$.extend(data, {
					id:     generateId(),
					ready:  false,
					text:   '',
					resize: false,
					hand:   false
				});

				ZeroClipboard.clients[data.id] = this;

				// grab this elements size
				var outerWidth  = $$.outerWidth();
				if (outerWidth === 0) { outerWidth++; }
				var outerHeight = $$.outerHeight();
				if (outerHeight === 0) { outerHeight++; }

				// create a placeholder div for the SWFObject
				clipboard_id = zeroclipboard + '_swf_' + data.id;
				var placeholder = $('<div></div>').attr('id', clipboard_id);

				// create our clipboard and container
				var container = $('<div></div>').css('position', 'absolute');

				container.append(placeholder).appendTo('body');

				swfobject.embedSWF(ZeroClipboard.moviepath, clipboard_id,
					outerHeight, outerHeight,
					'9.0.0', '',
				{
					'id':   data.id,
					width:  outerWidth,
					height: outerHeight
				}, {
					wmode:             'transparent',
					bgcolor:           '#ffffff',
					quality:           'best',
					loop:              false,
					allowscriptaccess: 'always',
					allowfullscreen:   false
				});

				$$.

				// We check for a resize event called on the element
				// Note! This only works with the jQuery Resize Event from Ben Alman
				// Url: http://benalman.com/projects/jquery-resize-plugin/
				resize(function () {
					data.resize = true;
					ZeroClipboard.update(data.id);
				}).

				// Add an event to test when the element is destroyed to also
				// destroy the flash object paired with the element.
				bind('remove', function () {
					$$.zeroclipboard({destroy: true});
				}).

				// run update
				zeroclipboard(options);
			}
		});
	};
})(jQuery);
