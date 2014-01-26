// Taken from https://github.com/joyent/node/blob/master/lib/path.js



// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
	// if the path tries to go above the root, `up` ends up > 0
	var up = 0;
	for (var i = parts.length - 1; i >= 0; i--) {
		var last = parts[i];
		if (last === '.') {
			parts.splice(i, 1);
		} else if (last === '..') {
			parts.splice(i, 1);
			up++;
		} else if (up) {
			parts.splice(i, 1);
			up--;
		}
	}

	// if the path is allowed to go above the root, restore leading ..s
	if (allowAboveRoot) {
		for (; up--; up) {
			parts.unshift('..');
		}
	}

	return parts;
}

var splitPathRe =
	/^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/;
var splitPath = function(filename) {
	return splitPathRe.exec(filename).slice(1);
};

var isBrowser = typeof window !== 'undefined';

if (!isBrowser) {
	var path = require('path');
}

exports.isAbsolute = function(_path) {
	if (isBrowser) {
		return _path.charAt(0) === '/';
	} else {
		return path.isAbsolute.call({}, _path);
	}
};

exports.normalize = function(_path) {
	if (isBrowser) {
		var isAbsolute = exports.isAbsolute(_path),
			trailingSlash = _path[_path.length - 1] === '/',
			segments = _path.split('/'),
			nonEmptySegments = [];

		// Normalize the path
		for (var i = 0; i < segments.length; i++) {
			if (segments[i]) {
				nonEmptySegments.push(segments[i]);
			}
		}
		_path = normalizeArray(nonEmptySegments, !isAbsolute).join('/');

		if (!_path && !isAbsolute) {
			_path = '.';
		}
		if (_path && trailingSlash) {
			_path += '/';
		}

		return (isAbsolute ? '/' : '') + _path;
	} else {
		return path.normalize.call({}, _path);
	}
};

exports.join = function() {
	if (isBrowser) {
		var _path = '';
		for (var i = 0; i < arguments.length; i++) {
			var segment = arguments[i];
			if (typeof segment != 'string') {
				throw new TypeError('Arguments to path.join must be strings');
			}
			if (segment) {
				if (!_path) {
					_path += segment;
				} else {
					_path += '/' + segment;
				}
			}
		}
		return exports.normalize(_path);
	} else {
		return path.join.apply({}, arguments);
	}
};

exports.dirname = function(_path) {
	if (isBrowser) {
		var result = splitPath(_path),
			root = result[0],
			dir = result[1];

		if (!root && !dir) {
			// No dirname whatsoever
			return '.';
		}

		if (dir) {
			// It has a dirname, strip trailing slash
			dir = dir.substr(0, dir.length - 1);
		}

		return root + dir;
	} else {
		return path.dirname.call({}, _path);
	}
};