if typeof window != 'undefined'
	throw new Error 'Translator API can not be used in browser.'

Loader = require './Loaders/Loader'
Translator = require './Translator'

fs = require 'fs'
path = require 'path'
callsite = require 'callsite'
Finder = require 'fs-finder'

class Api


	configPath: null

	config: null

	translator: null

	loader: null

	language: 'en'

	languages: null


	constructor: (@configPath, @language = @language) ->
		if @configPath.charAt(0) == '.'
			stack = callsite()
			@configPath = path.join(path.dirname(stack[1].getFileName()), @configPath)

		@configPath = path.normalize(@configPath)

		@config = JSON.parse(fs.readFileSync(@configPath, encoding: 'utf8'))

		if typeof @config.path == 'undefined'
			@config.path = '.'

		if typeof @config.loader == 'undefined'
			@config.loader = 'Json'

		if typeof @config.languages == 'undefined'
			@config.languages = []

		if @config.path.charAt(0) == '.'
			@config.path = path.join(path.dirname(@configPath), @config.path)

		@translator = new Translator(@configPath)
		@loader = new (require './Loaders/' + @config.loader)(@config.path)


	release: ->
		@languages = null


	getLanguages: ->
		if @languages == null
			@languages = []

			for file in Finder.from(@config.path).findFiles('.*.json')
				language = path.basename(file).split('.')[0]
				if @languages.indexOf(language) == -1
					@languages.push(language)

			for language in @config.languages
				if @languages.indexOf(language) == -1
					@languages.push(language)

		return @languages


	hasLanguage: (language) ->
		return @getLanguages().indexOf(language) != -1


	addLanguage: (language) ->
		if !@hasLanguage(language)
			@languages.push(language)
			@config.languages.push(language)
			fs.writeFileSync(@configPath, JSON.stringify(@config, null, '\t'))


	getDictionaries: ->
		result = []

		for file in Finder.from(@config.path).findFiles(@language + '.*.json')
			name = path.relative(@config.path, file)
			dir = path.dirname(name)
			name = path.basename(name, path.extname(name)).replace(new RegExp('^' + @language + '\.'), '')

			result.push(path.join(dir, name))

		return @createTree(result)


	addDictionary: (dictionary) ->
		info = @translator.getMessageInfo(dictionary + '.buf')
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		if fs.existsSync(_path)
			throw new Error "Dictionary '#{dictionary}' already exists."

		fs.writeFileSync(_path, '{}')


	renameDictionary: (oldName, newName) ->
		info = @translator.getMessageInfo(oldName + '.buf')
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		if !fs.existsSync(_path)
			throw new Error "Dictionary '#{oldName}' does not exists."

		newInfo = @translator.getMessageInfo(newName + '.buf')
		newPath = @loader.getFileSystemPath(newInfo.path, newInfo.category, @language)
		if fs.existsSync(newPath)
			throw new Error "Dictionary '#{newName}' already exists."

		fs.renameSync(_path, newPath)


	removeDictionary: (dictionary) ->
		info = @translator.getMessageInfo(dictionary + '.buf')
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		if !fs.existsSync(_path)
			throw new Error "Dictionary '#{dictionary}' does not exists."

		fs.unlinkSync(_path)


	getTranslations: (dictionary) ->
		info = @translator.getMessageInfo(dictionary + '.buf')
		files = @translator.loadCategory(info.path, info.category, @language)
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		delete require.cache[_path]
		return files


	addTranslation: (dictionary, name, translation) ->
		info = @translator.getMessageInfo(dictionary + '.' + name)
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		data = @getTranslations(dictionary)
		if typeof data[info.name] != 'undefined'
			throw new Error "Translation '#{name}' already exists in '#{dictionary}' dictionary."

		data[info.name] = translation
		data = JSON.stringify(data, null, '\t')
		fs.writeFileSync(_path, data)


	editTranslation: (dictionary, name, translation) ->
		info = @translator.getMessageInfo(dictionary + '.' + name)
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		data = @getTranslations(dictionary)
		if typeof data[info.name] == 'undefined'
			throw new Error "Translation '#{name}' does not exists in '#{dictionary}' dictionary."

		data[info.name] = translation
		data = JSON.stringify(data, null, '\t')
		fs.writeFileSync(_path, data)


	renameTranslation: (dictionary, oldName, newName) ->
		info = @translator.getMessageInfo(dictionary + '.' + oldName)
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		data = @getTranslations(dictionary)
		if typeof data[info.name] == 'undefined'
			throw new Error "Translation '#{oldName}' does not exists in '#{dictionary}' dictionary."

		if typeof data[newName] != 'undefined'
			throw new Error "Translation '#{newName}' already exists in '#{dictionary}' dictionary."

		data[newName] = data[oldName]
		delete data[oldName]

		data = JSON.stringify(data, null, '\t')
		fs.writeFileSync(_path, data)


	removeTranslation: (dictionary, name) ->
		info = @translator.getMessageInfo(dictionary + '.' + name)
		_path = @loader.getFileSystemPath(info.path, info.category, @language)
		data = @getTranslations(dictionary)
		delete data[name]
		data = JSON.stringify(data, null, '\t')
		fs.writeFileSync(_path, data)


	createTree: (paths) ->
		result = {}
		count = 0

		for _path in paths
			parts = _path.split(path.sep)
			buf = result
			for part in parts
				if typeof buf[part] == 'undefined'
					buf[part] = {}

				buf = buf[part]

			count++

		return result


module.exports = Api