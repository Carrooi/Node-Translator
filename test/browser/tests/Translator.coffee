Translator = require '/lib/Translator'
BrowserLocalStorage = require 'cache-storage/Storage/BrowserLocalStorage'
Cache = require 'cache-storage'

dir = '/test/data'

translator = null

describe 'Translator', ->

	beforeEach( ->
		translator = new Translator(dir)
		translator.language = 'en'
	)

	afterEach( ->
		translator = null
	)

	describe '#constructor()', ->
		it 'should contain some plural forms', ->
			expect(translator.plurals).not.to.be.eql({})

	describe '#normalizeTranslations()', ->
		it 'should return normalized object with dictionary', ->
			expect(translator.normalizeTranslations(
				car: 'car'
				bus: ['bus']
			)).to.be.eql(
				car: ['car']
				bus: ['bus']
			)

		it 'should return normalized translations without comments', ->
			expect(translator.normalizeTranslations(
				one: [
					'# hello #'
					'car'
					'# house #'
					'something'
				]
			)).to.be.eql(
				one: [
					'car'
					'something'
				]
			)

		it 'should return normalized translations for list with comments', ->
			expect(translator.normalizeTranslations(
				one: [
					['first']
					'# comment #'
					[
						'second'
						'# comment #'
					]
					['third']
				]
			)).to.be.eql(
				one: [
					['first']
					['second']
					['third']
				]
			)

		it 'should return normalized translations for list with new syntax', ->
			expect(translator.normalizeTranslations(
				'-- list': [
					'first'
					'second'
					'third'
				]
			)).to.be.eql(
				list: [
					['first']
					['second']
					['third']
				]
			)

	describe '#getMessageInfo()', ->
		it 'should return information about dictionary from message to translate', ->
			expect(translator.getMessageInfo('web.pages.homepage.promo.title')).to.be.eql(
				path: 'web/pages/homepage'
				category: 'promo'
				name: 'title'
			)

	describe '#loadCategory()', ->
		it 'should load parsed dictionary', ->
			expect(translator.loadCategory('web/pages/homepage', 'simple')).to.be.eql(
				title: ['Title of promo box']
			)

		it 'should return empty object if dictionary does not exists', ->
			expect(translator.loadCategory('some/unknown', 'translation')).to.be.eql({})

	describe '#findTranslation()', ->
		it 'should return english translations from dictionary', ->
			expect(translator.findTranslation('web.pages.homepage.promo.title')).to.be.eql(['Title of promo box'])

		it 'should return null when translation does not exists', ->
			expect(translator.findTranslation('some.unknown.translation')).to.be.null

	describe '#pluralize()', ->
		it 'should return right version of translation(s) by count', ->
			cars = ['1 car', '%count% cars']
			expect(translator.pluralize('car', cars, 1)).to.be.equal('1 car')
			expect(translator.pluralize('car', cars, 4)).to.be.equal('%count% cars')

			fruits = [['1 apple', '%count% apples'], ['1 orange', '%count% oranges']]
			expect(translator.pluralize('list', fruits, 1)).to.be.eql(['1 apple', '1 orange'])
			expect(translator.pluralize('list', fruits, 4)).to.be.eql(['%count% apples', '%count% oranges'])

	describe '#prepareTranslation()', ->
		it 'should return expanded translation with arguments', ->
			translator.addReplacement('item', 'car')
			expect(translator.prepareTranslation('%item% has got %count% %append%.',
				count: 5
				append: 'things'
			)).to.be.equal('car has got 5 things.')

	describe '#applyReplacements()', ->
		it 'should add replacements to text', ->
			expect(translator.applyReplacements('%one% %two% %three%',
				one: 1
				two: 2
				three: 3
			)).to.be.equal('1 2 3')

	describe '#translate()', ->
		it 'should return translated text from dictionary', ->
			expect(translator.translate('web.pages.homepage.promo.title')).to.be.equal('Title of promo box')

		it 'should return original text if text is eclosed in \':\'', ->
			expect(translator.translate(':do.not.translate.me:')).to.be.equal('do.not.translate.me')

		it 'should return array of list', ->
			expect(translator.translate('web.pages.homepage.promo.list')).to.be.eql(['1st item', '2nd item', '3rd item', '4th item', '5th item'])

		it 'should return translation for plural form', ->
			expect(translator.translate('web.pages.homepage.promo.cars', 3)).to.be.equal('3 cars')

		it 'should return translation of list for plural form', ->
			expect(translator.translate('web.pages.homepage.promo.fruits', 3)).to.be.eql(['3 bananas', '3 citrons', '3 oranges'])

		it 'should return translation with replacement in message', ->
			translator.addReplacement('one', 1)
			translator.addReplacement('dictionary', 'promo')
			expect(translator.translate('web.pages.homepage.%dictionary%.%name%', null,
				two: 2
				name: 'advanced'
			)).to.be.equal('1 2')

		it 'should translate with parameters in place of count argument', ->
			expect(translator.translate('web.pages.homepage.promo.advanced', {one: '1', two: 2})).to.be.equal('1 2')

		it 'should translate one item from list in translate method', ->
			expect(translator.translate('web.pages.homepage.promo.newList[0]')).to.be.equal('first')
			expect(translator.translate('web.pages.homepage.promo.newList[1]')).to.be.equal('second')
			expect(translator.translate('web.pages.homepage.promo.newList[2]')).to.be.equal('third')

		it 'should throw an error when translating one item from non-list', ->
			expect( -> translator.translate('web.pages.homepage.promo.title[5]') ).throw(Error)

		it 'should throw an error when translating one item which does not exists', ->
			expect( -> translator.translate('web.pages.homepage.promo.newList[5]') ).throw(Error)

	describe '#translatePairs()', ->
		it 'should throw an error if message to translate are not arrays', ->
			expect( -> translator.translatePairs('web.pages.homepage.promo', 'title', 'list') ).throw(Error)

		it 'should throw an error if keys and values have not got the same length', ->
			expect( -> translator.translatePairs('web.pages.homepage.promo', 'list', 'keys') ).throw(Error)

		it 'should return object with keys and values translations', ->
			expect(translator.translatePairs('web.pages.homepage.promo', 'keys', 'values')).to.be.eql(
				'1st title': '1st text'
				'2nd title': '2nd text'
				'3rd title': '3rd text'
				'4th title': '4th text'
			)

	describe '#translateMap()', ->
		it 'should throw an error if object is not array or object', ->
			expect( -> translator.translateMap(new Date)).to.throw(Error)

		it 'should translate array', ->
			expect(translator.translateMap(['web.pages.homepage.promo.title', 'web.pages.homepage.promo.info'])).to.be.eql([
				'Title of promo box'
				'Some info text'
			])

		it 'should translate object', ->
			t =
				title: 'web.pages.homepage.promo.title'
				info: 'web.pages.homepage.promo.info'
			expect(translator.translateMap(t)).to.be.eql(
				title: 'Title of promo box'
				info: 'Some info text'
			)

		it 'should translate array with plural forms translations', ->
			expect(translator.translateMap(['web.pages.homepage.promo.cars', 'web.pages.homepage.promo.mobile'], 6)).to.be.eql([
				'6 cars'
				'6 mobiles'
			])

		it 'should translate array with arguments', ->
			expect(translator.translateMap(['web.pages.homepage.promo.advanced'], {one: 1, two: 2})).to.be.eql(['1 2'])

		it 'should translate array with base path', ->
			expect(translator.translateMap(['title', 'info'], 'web.pages.homepage.promo')).to.be.eql([
				'Title of promo box'
				'Some info text'
			])

		it 'should translate array with list', ->
			expect(translator.translateMap(['web.pages.homepage.promo.fruits'], 4)).to.be.eql([[
				'4 bananas'
				'4 citrons'
				'4 oranges'
			]])

	describe '#setCacheStorage()', ->
		it 'should throw an exception if storage is not the right type', ->
			expect( -> translator.setCacheStorage(new Array) ).throw(Error)

		it 'should create cache instance', ->
			translator.setCacheStorage(new BrowserLocalStorage)
			expect(translator.cache).to.be.an.instanceof(Cache)