expect = require('chai').expect
fs = require 'fs'
path = require 'path'

Api = require '../../../lib/Api'

api = null
backup = {}

describe 'Api', ->

	beforeEach( ->
		api = new Api('../../data/config.json')
		paths = [
			api.configPath
			path.join(api.config.path, './web/pages/homepage/en.promo.json')
		]

		for _path in paths
			backup[_path] = fs.readFileSync(_path, encoding: 'utf8')
	)

	afterEach( ->
		for _path, data of backup
			fs.writeFileSync(_path, data)
	)

	describe '#getLanguages()', ->

		it 'should get all used languages', ->
			expect(api.getLanguages()).to.have.members(['en', 'cs', 'sk'])

	describe '#hasLanguage()', ->

		it 'should return true if language exists', ->
			expect(api.hasLanguage('cs')).to.be.true

		it 'should return true if language does not exists', ->
			expect(api.hasLanguage('fr')).to.be.false

	describe '#addLanguage()', ->

		it 'should not do anything if language already exists', ->
			api.addLanguage('cs')
			api.release()
			expect(api.getLanguages()).to.have.members(['en', 'cs', 'sk'])

		it 'should add new language', ->
			api.addLanguage('fr')
			api.release()
			expect(api.getLanguages()).to.have.members(['en', 'cs', 'sk', 'fr'])

	describe '#getDictionaries()', ->

		it 'should get list of all dictionaries for selected language', ->
			expect(api.getDictionaries()).to.be.eql(
				first: {}
				web:
					pages:
						homepage:
							cached: {}
							promo: {}
							simple: {}
			)

	describe '#addDictionary()', ->

		it 'should throw an error if dictionary already exists', ->
			expect( -> api.addDictionary('web.pages.homepage.simple')).to.throw(Error, "Dictionary 'web.pages.homepage.simple' already exists.")

		it 'should create new dictionary', ->
			_path = path.join(api.config.path, './web/pages/homepage/en.newDictionary.json')
			api.addDictionary('web.pages.homepage.newDictionary')
			expect(api.getDictionaries().web.pages.homepage).to.have.keys([
				'simple', 'cached', 'promo', 'newDictionary'
			])
			expect(fs.readFileSync(_path, encoding: 'utf8')).to.be.equal('{}')
			fs.unlinkSync(_path)

	describe '#renameDictionary()', ->

		it 'should throw an error if source dictionary does not exists', ->
			expect( -> api.renameDictionary('unknown.dictionary', 'new.name')).to.throw(Error, "Dictionary 'unknown.dictionary' does not exists.")

		it 'should throw an error if target dictionary already exists', ->
			expect( -> api.renameDictionary('web.pages.homepage.promo', 'web.pages.homepage.simple')).to.throw(Error, "Dictionary 'web.pages.homepage.simple' already exists.")

	describe '#removeDictionary()', ->

		it 'should throw an error if source dictionary does not exists', ->
			expect( -> api.removeDictionary('unknown.dictionary')).to.throw(Error, "Dictionary 'unknown.dictionary' does not exists.")

		it 'should remove dictionary', ->
			api.removeDictionary('web.pages.homepage.promo')
			expect(api.getDictionaries().web.pages.homepage).to.have.keys([
				'simple', 'cached'
			])

	describe '#getTranslations()', ->

		it 'should load all translations in dictionary', ->
			expect(api.getTranslations('web.pages.homepage.simple')).to.be.eql(
				title: ['Title of promo box']
			)

	describe '#addTranslation()', ->

		it 'should throw an error if translation already exists', ->
			expect( -> api.addTranslation('web.pages.homepage.promo', 'title', 'New title')).to.throw(Error, "Translation 'title' already exists in 'web.pages.homepage.promo' dictionary.")

		it 'should add new translation', ->
			api.addTranslation('web.pages.homepage.promo', 'subtitle', 'New subtitle')
			translations = api.getTranslations('web.pages.homepage.promo')
			expect(translations).to.have.keys(
				'title', 'info', 'list', 'cars', 'mobile', 'fruits', 'keys', 'values', 'advanced', 'newList', 'subtitle'
			)
			expect(translations.subtitle).to.be.equal('New subtitle')

	describe '#editTranslation()', ->

		it 'should throw an error if translation does not exists', ->
			expect( -> api.editTranslation('web.pages.homepage.promo', 'subtitle', 'New subtitle')).to.throw(Error, "Translation 'subtitle' does not exists in 'web.pages.homepage.promo' dictionary.")

		it 'should change translation', ->
			api.editTranslation('web.pages.homepage.promo', 'title', 'New title')
			expect(api.getTranslations('web.pages.homepage.promo').title).to.be.eql('New title')

	describe '#renameTranslation()', ->

		it 'should throw an error if source translation does not exists', ->
			expect( -> api.renameTranslation('web.pages.homepage.promo', 'subtitle', '_subtitle')).to.throw(Error, "Translation 'subtitle' does not exists in 'web.pages.homepage.promo' dictionary.")

		it 'should throw an error if target translation already exists', ->
			expect( -> api.renameTranslation('web.pages.homepage.promo', 'title', 'info')).to.throw(Error, "Translation 'info' already exists in 'web.pages.homepage.promo' dictionary.")

		it 'should rename translation', ->
			api.renameTranslation('web.pages.homepage.promo', 'title', '_title')
			translations = api.getTranslations('web.pages.homepage.promo')
			expect(translations).to.have.keys([
				'_title', 'info', 'list', 'cars', 'mobile', 'fruits', 'keys', 'values', 'advanced', 'newList',
			])
			expect(translations._title).to.be.eql(['Title of promo box'])

	describe '#removeTranslation()', ->

		it 'should remove translation', ->
			api.removeTranslation('web.pages.homepage.promo', 'title')
			expect(api.getTranslations('web.pages.homepage.promo')).to.have.keys(
				'info', 'list', 'cars', 'mobile', 'fruits', 'keys', 'values', 'advanced', 'newList'
			)