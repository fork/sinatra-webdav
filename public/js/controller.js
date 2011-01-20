(function() {
	var exports = this;

	function Controller(type) {
		return Controller[type] || Controller[Controller.defaultType];
	};
	Controller['application/octet-stream'] = function(url) {
		window.open(url);
	};
	Controller.defaultType = 'application/octet-stream';

	exports.Controller = Controller;
})();
