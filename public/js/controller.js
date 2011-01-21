(function() {
	var exports = this;

	function Controller(specialType) {
		var genericType = specialType.split('/')[0];
		var handler = Controller[specialType] || Controller[genericType];

		return handler || Controller[Controller.defaultType];
	};
	Controller['application/octet-stream'] = function(url) {
		window.open(url);
	};
	Controller.defaultType = 'application/octet-stream';

	exports.Controller = Controller;
})();
