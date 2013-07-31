(function () {

	var should = require('should');
	var path = require('path');
	var Translator = require('../lib/Translator');

	var translator = new Translator;
	translator.language = 'en';
	translator.directory = path.resolve('./data');

})();