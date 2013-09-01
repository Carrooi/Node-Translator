(function () {

	var should = require('should');
	var path = require('path');
	var Translator = require('../lib/Translator');

	var _path = path.resolve('./data');

	var translator;

	describe('Translator', function() {

		beforeEach(function() {
			translator = new Translator;
			translator.language = 'en';
			translator.directory = _path;
		});

		afterEach(function() {
			translator = null;
		});

		describe('#constructor', function() {
			it('should contain some plural forms', function() {
				translator.plurals.should.not.be.eql({});
			});
		});

		describe('#normalizeTranslations()', function() {
			it('should return normalized object with dictionary', function() {
				translator.normalizeTranslations({car: 'car', bus: ['bus']}).should.eql({car: ['car'], bus: ['bus']});
			});
		});

		describe('#getMessageInfO()', function() {
			it('should return information about dictionary from message to translate', function() {
				translator.getMessageInfo('web.pages.homepage.promo.title').should.eql({
					path: 'web/pages/homepage',
					category: 'promo',
					name: 'title'
				});
			});
		});

		describe('#loadCategory()', function() {
			it('should load parsed dictionary', function() {
				translator.loadCategory('web/pages/homepage', 'simple').should.eql({
					title: ['Title of promo box']
				});
			});

			it('should return empty object if dictionary does not exists', function() {
				translator.loadCategory('some/unknown', 'translation').should.eql({});
			});
		});

		describe('#findTranslation()', function() {
			it('should return english translations from dictionary', function() {
				translator.findTranslation('web.pages.homepage.promo.title').should.eql(['Title of promo box']);
			});

			it('should return null when translation does not exists', function() {
				should.not.exist(translator.findTranslation('some.unknown.translation'));
			});
		});

		describe('#pluralize()', function() {
			it('should return right version of translation(s) by count', function() {
				var cars = ['1 car', '%count% cars'];
				translator.pluralize('car', cars, 1).should.be.equal('1 car');
				translator.pluralize('car', cars, 4).should.be.equal('%count% cars');

				var fruits = [['1 apple', '%count% apples'], ['1 orange', '%count% oranges']];
				translator.pluralize('list', fruits, 1).should.eql(['1 apple', '1 orange']);
				translator.pluralize('list', fruits, 4).should.eql(['%count% apples', '%count% oranges']);
			});
		});

		describe('#prepareTranslation()', function() {
			it('should return expanded translation with arguments', function() {
				translator.addReplacement('item', 'car');
				translator.prepareTranslation('%item% has got %count% %append%.', 5, {append: 'things'}).should.be.equal('car has got 5 things.');
				translator.removeReplacement('item');
			});
		});

		describe('#translate()', function() {
			it('should return translated text from dictionary', function() {
				translator.translate('web.pages.homepage.promo.title').should.be.equal('Title of promo box');
			});

			it('should return original text if text is eclosed in \':\'', function() {
				translator.translate(':do.not.translate.me:').should.be.equal('do.not.translate.me');
			});

			it('should return array of list', function() {
				translator.translate('web.pages.homepage.promo.list').should.be.eql(['1st item', '2nd item', '3rd item', '4th item', '5th item']);
			});

			it('should return translation for plural form', function() {
				translator.translate('web.pages.homepage.promo.cars', 3).should.be.equal('3 cars');
			});

			it('should return translation of list for plural form', function() {
				translator.translate('web.pages.homepage.promo.fruits', 3).should.be.eql(['3 bananas', '3 citrons', '3 oranges']);
			});
		});

	});

})();