(function () {
	var exports = this;
	var utils   = exports.utils || {};

	exports.utils = utils;

	function Sorter(property) {
		var smaller = -1, greater = 1;

		function sorter(a, b) {
			a = a[sorter.property];
			b = b[sorter.property];

			if (a < b) return smaller;
			if (a > b) return greater;

			return 0;
		}
		sorter.reverse    = function reverse() {
			smaller *= -1;
			greater *= -1;
		};
		sorter.descending = function descending() {
			smaller = -1;
			greater =  1;
		};
		sorter.ascending  = function ascending() {
			smaller =  1;
			greater = -1;
		};
		sorter.property   = property;

		return sorter;
	}
	utils.Sorter = Sorter;

	var prefixTable = {
		IEC: [
		null,
		{ prefix: 'kibi', abbrev: 'Ki' },
		{ prefix: 'mebi', abbrev: 'Mi' },
		{ prefix: 'gibi', abbrev: 'Gi' },
		{ prefix: 'tebi', abbrev: 'Ti' },
		{ prefix: 'pebi', abbrev: 'Pi' },
		{ prefix: 'exbi', abbrev: 'Ei' },
		{ prefix: 'zebi', abbrev: 'Zi' },
		{ prefix: 'yobi', abbrev: 'Yi' }
		],
		SI: [
		null,
		{ prefix: 'kilo', abbrev: 'k' },
		{ prefix: 'mega', abbrev: 'M' },
		{ prefix: 'giga', abbrev: 'G' },
		{ prefix: 'tera', abbrev: 'T' },
		{ prefix: 'peta', abbrev: 'P' },
		{ prefix: 'exa', abbrev: 'E' },
		{ prefix: 'zetta', abbrev: 'Z' },
		{ prefix: 'yotta', abbrev: 'Y' }
		]
	};
	var divider = { SI: 1000, IEC: 1024 };

	// takes integer number and returns something approximating scientific
	// notation
	function normalize(magnitude, div) {            
		var q = Math.floor(magnitude / div);
		var pow = (q) ? 1 : 0;

		while (q && q > div) {
			q /= div;
			pow += 1;
		};

		return { q: q, pow: pow };
	}

	function FormatterFactory(table, div, unit) {
		function formatter(text) {
			// validate text of currect element as number
			if (/[^a-fA-F0-9]/.test(text)) { return text; }

			var n = normalize(new Number(text), div);

			if (!n.pow) { return text + ' ' + unit; }
			return n.q.toFixed(2) + ' ' + table[n.pow].abbrev + unit;
		}
		return formatter;
	}

	function Formatter(system, unit) {
		return FormatterFactory[system](unit);
	}
	Formatter.IEC = function(unit) {
		return FormatterFactory(prefixTable.IEC, divider.IEC, unit);
	};
	Formatter.SI = function(unit) {
		return FormatterFactory(prefixTable.SI, divider.SI, unit);
	};
	utils.Formatter = Formatter;


	function relativeTime(now_threshold) {
		var delta = new Date() - this;

		now_threshold = parseInt(now_threshold, 10);

		if (isNaN(now_threshold)) {
			now_threshold = 0;
		}

		if (delta <= now_threshold) {
			return 'Just now';
		}

		var units = null;
		var conversions = {
			millisecond: 1, // ms    -> ms
			second: 1000,   // ms    -> sec
			minute: 60,     // sec   -> min
			hour:   60,     // min   -> hour
			day:    24,     // hour  -> day
			month:  30,     // day   -> month (roughly)
			year:   12      // month -> year
		};

		for (var key in conversions) {
			if (delta < conversions[key]) {
				break;
			} else {
				units = key; // keeps track of the selected key over the iteration
				delta = delta / conversions[key];
			}
		}

		// pluralize a unit when the difference is greater than 1.
		delta = Math.floor(delta);
		if (delta !== 1) { units += "s"; }
		return [delta, units, "ago"].join(" ");
	};
	utils.relativeTime = relativeTime;

})();
