should = require 'should'
path = require 'path'
fs = require 'fs'
Translator = require '../lib/Translator'
FileStorage = require 'cache-storage/Storage/FileStorage'
Cache = require 'cache-storage'

_path = path.resolve './data'

translator = null

describe 'Translator', ->

	beforeEach( ->
		translator = new Translator
		translator.language = 'en'
		translator.directory = _path
	)

	afterEach( ->
		translator = null
	)

	describe '#constructor()', ->
		it 'should contain some plural forms', ->
			translator.plurals.should.not.be.eql({})

	describe '#normalizeTranslations()', ->
		it 'should return normalized object with dictionary', ->
			translator.normalizeTranslations(
				car: 'car'
				bus: ['bus']
			).should.eql(
				car: ['car']
				bus: ['bus']
			)

		it 'should return normalized translations without comments', ->
			translator.normalizeTranslations(
				one: [
					'# hello #'
					'car'
					'# house #'
					'something'
				]
			).should.be.eql(
				one: [
					'car'
					'something'
				]
			)

		it 'should return normalized translations for list with comments', ->
			translator.normalizeTranslations(
				one: [
					['first']
					'# comment #'
					[
						'second'
						'# comment #'
					]
					['third']
				]
			).should.be.eql(
				one: [
					['first']
					['second']
					['third']
				]
			)

		it 'should return normalized translations for list with new syntax', ->
			translator.normalizeTranslations(
				'-- list': [
					'first'
					'second'
					'third'
				]
			).should.be.eql(
				list: [
					['first']
					['second']
					['third']
				]
			)

	describe '#getMessageInfo()', ->
		it 'should return information about dictionary from message to translate', ->
			translator.getMessageInfo('web.pages.homepage.promo.title').should.eql(
				path: 'web/pages/homepage'
				category: 'promo'
				name: 'title'
			)

	describe '#loadCategory()', ->
		it 'should load parsed dictionary', ->
			translator.loadCategory('web/pages/homepage', 'simple').should.eql(
				title: ['Title of promo box']
			)

		it 'should return empty object if dictionary does not exists', ->
			translator.loadCategory('some/unknown', 'translation').should.eql({})

	describe '#findTranslation()', ->
		it 'should return english translations from dictionary', ->
			translator.findTranslation('web.pages.homepage.promo.title').should.eql(['Title of promo box'])

		it 'should return null when translation does not exists', ->
			should.not.exist(translator.findTranslation('some.unknown.translation'))

	describe '#pluralize()', ->
		it 'should return right version of translation(s) by count', ->
			cars = ['1 car', '%count% cars']
			translator.pluralize('car', cars, 1).should.be.equal('1 car')
			translator.pluralize('car', cars, 4).should.be.equal('%count% cars')

			fruits = [['1 apple', '%count% apples'], ['1 orange', '%count% oranges']]
			translator.pluralize('list', fruits, 1).should.eql(['1 apple', '1 orange'])
			translator.pluralize('list', fruits, 4).should.eql(['%count% apples', '%count% oranges'])

	describe '#prepareTranslation()', ->
		it 'should return expanded translation with arguments', ->
			translator.addReplacement('item', 'car')
			translator.prepareTranslation('%item% has got %count% %append%.',
				count: 5
				append: 'things'
			).should.be.equal('car has got 5 things.')
			translator.removeReplacement('item')

	describe '#applyReplacements()', ->
		it 'should add replacements to text', ->
			translator.applyReplacements('%one% %two% %three%',
				one: 1
				two: 2
				three: 3
			).should.be.equal('1 2 3')

	describe '#translate()', ->
		it 'should return translated text from dictionary', ->
			translator.translate('web.pages.homepage.promo.title').should.be.equal('Title of promo box')

		it 'should return original text if text is eclosed in \':\'', ->
			translator.translate(':do.not.translate.me:').should.be.equal('do.not.translate.me')

		it 'should return array of list', ->
			translator.translate('web.pages.homepage.promo.list').should.be.eql(['1st item', '2nd item', '3rd item', '4th item', '5th item'])

		it 'should return translation for plural form', ->
			translator.translate('web.pages.homepage.promo.cars', 3).should.be.equal('3 cars')

		it 'should return translation of list for plural form', ->
			translator.translate('web.pages.homepage.promo.fruits', 3).should.be.eql(['3 bananas', '3 citrons', '3 oranges'])

		it 'should return translation with replacement in message', ->
			translator.addReplacement('one', 1)
			translator.addReplacement('dictionary', 'promo')
			translator.translate('web.pages.homepage.%dictionary%.%name%', null,
				two: 2
				name: 'advanced'
			).should.be.equal('1 2')

		it 'should translate with parameters in place of count argument', ->
			t = translator.translate('web.pages.homepage.promo.advanced', {one: '1', two: 2})
			t.should.be.equal('1 2')

		it 'should translate one item from list in translate method', ->
			translator.translate('web.pages.homepage.promo.newList[0]').should.be.equal('first')
			translator.translate('web.pages.homepage.promo.newList[1]').should.be.equal('second')
			translator.translate('web.pages.homepage.promo.newList[2]').should.be.equal('third')

		it 'should throw an error when translating one item from non-list', ->
			( -> translator.translate('web.pages.homepage.promo.title[5]') ).should.throw()

		it 'should throw an error when translating one item which does not exists', ->
			( -> translator.translate('web.pages.homepage.promo.newList[5]') ).should.throw()

	describe '#translatePairs()', ->
		it 'should throw an error if message to translate are not arrays', ->
			( -> translator.translatePairs('web.pages.homepage.promo', 'title', 'list') ).should.throw()

		it 'should throw an error if keys and values have not got the same length', ->
			( -> translator.translatePairs('web.pages.homepage.promo', 'list', 'keys') ).should.throw()

		it 'should return object with keys and values translations', ->
			translator.translatePairs('web.pages.homepage.promo', 'keys', 'values').should.be.eql(
				'1st title': '1st text'
				'2nd title': '2nd text'
				'3rd title': '3rd text'
				'4th title': '4th text'
			)

	describe '#setCacheStorage()', ->
		it 'should throw an exception if storage is not the right type', ->
			( -> translator.setCacheStorage(new Array) ).should.throw()

		it 'should create cache instance', ->
			cachePath = path.resolve('./cache')
			translator.setCacheStorage(new FileStorage(cachePath))
			translator.cache.should.be.an.instanceOf(Cache)

	describe 'Cache', ->

		beforeEach( ->
			cachePath = path.resolve('./cache')
			translator.setCacheStorage(new FileStorage(cachePath))
		)

		afterEach( ->
			cachePath = path.resolve('./cache/__translator.json')
			dicPath = path.resolve('./data/web/pages/homepage/en.cached.json')
			fs.unlinkSync(cachePath) if fs.existsSync(cachePath)
			fs.writeFileSync(dicPath, '{"# version #": 1, "variable": "1"}')
		)

		describe '#translate()', ->
			it 'should load translation from cache', ->
				translator.translate('web.pages.homepage.promo.title')
				translator.cache.load('en:web/pages/homepage/promo').should.be.a('object').and.have.property('title')

			it 'should invalidate cache for dictionary after it is changed', ->
				dictionary = path.resolve('./data/web/pages/homepage/en.simple.json')
				data = fs.readFileSync(dictionary, encoding: 'utf-8')
				translator.translate('web.pages.homepage.simple.title')
				fs.writeFileSync(dictionary, data)
				translator.cache.invalidate()
				should.not.exists(translator.cache.load('en:web/pages/homepage/simple'))

			it 'should load data from dictionary with version', ->
				translator.translate('web.pages.homepage.cached.variable').should.be.equal('1')

			it 'should change data in dictionary with version, but load the old one', ->
				translator.translate('web.pages.homepage.cached.variable').should.be.equal('1')
				dicPath = path.resolve('./data/web/pages/homepage/en.cached.json')
				fs.writeFileSync(dicPath, '{"# version #": 1, "variable": "2"}')
				translator.invalidate()
				translator.translate('web.pages.homepage.cached.variable').should.be.equal('1')

			it 'should change data in dictionary with version and load it', ->
				translator.translate('web.pages.homepage.cached.variable').should.be.equal('1')
				dicPath = path.resolve('./data/web/pages/homepage/en.cached.json')
				fs.writeFileSync(dicPath, '{"# version #": 2, "variable": "2"}')
				translator.invalidate()
				name = require.resolve('./data/web/pages/homepage/en.cached')
				delete require.cache[name]
				translator.translate('web.pages.homepage.cached.variable').should.be.equal('2')