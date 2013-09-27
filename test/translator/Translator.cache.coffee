expect = require('chai').expect
path = require 'path'
fs = require 'fs'
Translator = require '../../lib/Translator'
FileStorage = require 'cache-storage/Storage/FileStorage'
Cache = require 'cache-storage'

dir = path.normalize __dirname + '/../data'
cache = path.normalize __dirname + '/../cache'

translator = null

describe 'Translator.cache', ->

	beforeEach( ->
		translator = new Translator
		translator.language = 'en'
		translator.directory = dir

		translator.setCacheStorage(new FileStorage(cache))
	)

	afterEach( ->
		translator = null

		cachePath = cache + '/__translator.json'
		dicPath = dir + '/web/pages/homepage/en.cached.json'
		fs.unlinkSync(cachePath) if fs.existsSync(cachePath)
		fs.writeFileSync(dicPath, '{"# version #": 1, "variable": "1"}')
	)

	describe '#translate()', ->
		it 'should load translation from cache', ->
			translator.translate('web.pages.homepage.promo.title')
			t = translator.cache.load('en:web/pages/homepage/promo')
			expect(t).to.be.an('object')
			expect(t).to.include.keys('title')

		it 'should invalidate cache for dictionary after it is changed', ->
			dictionary = dir + '/web/pages/homepage/en.simple.json'
			data = fs.readFileSync(dictionary, encoding: 'utf-8')
			translator.translate('web.pages.homepage.simple.title')
			fs.writeFileSync(dictionary, data)
			expect(translator.cache.load('en:web/pages/homepage/simple')).to.be.null

		it 'should load data from dictionary with version', ->
			expect(translator.translate('web.pages.homepage.cached.variable')).to.be.equal('1')

		it 'should change data in dictionary with version, but load the old one', ->
			expect(translator.translate('web.pages.homepage.cached.variable')).to.be.equal('1')
			dicPath = path.resolve('./data/web/pages/homepage/en.cached.json')
			fs.writeFileSync(dicPath, '{"# version #": 1, "variable": "2"}')
			translator.invalidate()
			expect(translator.translate('web.pages.homepage.cached.variable')).to.be.equal('1')

		it 'should change data in dictionary with version and load it', ->
			expect(translator.translate('web.pages.homepage.cached.variable')).to.be.equal('1')
			dicPath = path.resolve('./data/web/pages/homepage/en.cached.json')
			fs.writeFileSync(dicPath, '{"# version #": 2, "variable": "2"}')
			name = require.resolve(dir + '/web/pages/homepage/en.cached')
			delete require.cache[name]
			translator.invalidate()
			expect(translator.translate('web.pages.homepage.cached.variable')).to.be.equal('2')