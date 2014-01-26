Cache = require 'cache-storage'
Storage = require 'cache-storage/Storage/Storage'
Args = require 'normalize-arguments'
path = require './node/path'

pluralForms = require './pluralForms'
Loader = require './Loaders/Loader'
JsonLoader = require './Loaders/Json'

isBrowser = typeof window != 'undefined'

if !isBrowser
	callsite = require 'callsite'

class Translator


	loader: null

	language: null

	plurals: null

	replacements: null

	data: null

	cache: null


	constructor: (pathOrLoader) ->
		@plurals = {}
		@replacements = {}
		@data = {}

		if !pathOrLoader
			throw new Error 'You have to set path to base directory or to config file or loader.'

		if typeof pathOrLoader == 'string'
			if pathOrLoader.charAt(0) == '.' && isBrowser
				throw new Error 'Relative paths to dictionaries is not supported in browser.'

			if pathOrLoader.charAt(0) == '.'
				stack = callsite()
				pathOrLoader = path.join(path.dirname(stack[1].getFileName()), pathOrLoader)

			pathOrLoader = path.normalize(pathOrLoader)

			if pathOrLoader.match(/\.json$/) != null
				configPath = pathOrLoader
				pathOrLoader = require(configPath).path

				if pathOrLoader.charAt(0) == '.'
					pathOrLoader = path.join(path.dirname(configPath), pathOrLoader)

			pathOrLoader = new JsonLoader(pathOrLoader)

		@setLoader(pathOrLoader)

		for language, data of pluralForms
			@addPluralForm(language, data.count, data.form)


	expand: (main = null) ->
		if main == null
			main = if isBrowser then window else global

		main._ = => @translate.apply(@, arguments)
		main._m = => @translateMap.apply(@, arguments)
		main._p = => @translatePairs.apply(@, arguments)

		return main


	setLoader: (loader) ->
		if loader !instanceof Loader
			throw new Error 'Loader must be an instance of translator/Loaders/Loader.'

		@loader = loader


	invalidate: ->
		@data = {}


	setCacheStorage: (cacheStorage) ->
		if !cacheStorage instanceof Storage
			throw new Error 'Cache storage must be an instance of cache-storage/Storage/Storage.'

		@cache = new Cache cacheStorage, 'translator'


	addPluralForm: (language, count, form) ->
		@plurals[language] =
			count: count
			form: form
		return @


	addReplacement: (search, replacement) ->
		@replacements[search] = replacement
		return @


	removeReplacement: (search) ->
		if typeof @replacements[search] == 'undefined'
			throw new Error 'Replacement ' + search + ' was not found.'

		delete @replacements[search]
		return @


	loadCategory: (_path, name, language = @language) ->
		categoryName = _path + '/' + name
		if typeof @data[categoryName] == 'undefined'
			if @cache == null
				data = @loader.load(_path, name, language)
				data = @normalizeTranslations(data)
			else
				data = @cache.load(language + ':' + categoryName)

				if data == null
					data = @loader.load(_path, name, language)
					data = @normalizeTranslations(data)

					conds = {}
					if typeof window == 'undefined' || (typeof window != 'undefined' && window.require.simq == true && typeof window.require.version != 'undefined' && parseInt(window.require.version.replace(/\./g, '')) >= 510)
						_path = @loader.getFileSystemPath(_path, name, language)
						conds.files = [_path] if _path != null

					@cache.save(language + ':' + categoryName, data, conds)

				else
					file = @loader.load(_path, name, language)
					data = @normalizeTranslations(file)

			@data[categoryName] = data

		return @data[categoryName]


	normalizeTranslations: (translations) ->
		result = {}
		for name, translation of translations
			list = false
			if (match = name.match(/^--\s(.*)/)) != null
				name = match[1]
				list = true

			if typeof translation == 'string'
				result[name] = [translation]
			else if Object.prototype.toString.call(translation) == '[object Array]'
				result[name] = []
				for t in translation
					if typeof t == 'object'
						buf = []
						for sub in t
							if /^\#.*\#$/.test(sub) == false
								buf.push sub
						result[name].push buf
					else
						if /^\#.*\#$/.test(t) == false
							if list == true && typeof t != 'object' then t = [t]
							result[name].push t

		return result


	hasTranslation: (message, language = @language) ->
		return @findTranslation(message, language) != null


	findTranslation: (message, language = @language) ->
		info = @getMessageInfo(message)
		data = @loadCategory(info.path, info.category, language)
		return if typeof data[info.name] == 'undefined' then null else data[info.name]


	translate: (message, count = null, args = {}) ->
		params = Args(arguments, [Args.any, Args.number(null), Args.object({})])
		message = params[0]
		count = params[1]
		args = params[2]
		language = @language

		if typeof message != 'string' then return message

		if count != null then args.count = count

		if (match = message.match(/^\:(.*)\:$/)) != null
			message = match[1]
			if (match = message.match(/^[a-z]+\|(.*)$/)) != null
				message = match[1]
		else
			if (match = message.match(/^([a-z]+)\|(.*)$/)) != null
				language = match[1]
				message = match[2]

			if language == null
				throw new Error 'You have to set language'

			num = null
			if (match = message.match(/(.+)\[(\d+)\]$/)) != null
				message = match[1]
				num = parseInt(match[2])

			message = @applyReplacements(message, args)
			translation = @findTranslation(message, language)

			if num != null
				if !@isList(translation)
					throw new Error 'Translation ' + message + ' is not a list.'

				if typeof translation[num] == 'undefined'
					throw new Error 'Item ' + num + ' was not found in ' + message + ' translation.'

				translation = translation[num]

			if translation != null
				message = @pluralize(message, translation, count, language)

		message = @prepareTranslation(message, args)

		return message


	translatePairs: (message, key, value, count = null, args = {}) ->
		key = "#{message}.#{key}"
		value = "#{message}.#{value}"

		key = @translate(key, count, args)
		value = @translate(value, count, args)

		if Object.prototype.toString.call(key) != '[object Array]' || Object.prototype.toString.call(value) != '[object Array]'
			throw new Error 'Translations are not arrays.'

		if key.length != value.length
			throw new Error 'Keys and values translations have not got the same length.'

		result = {}
		for k, i in key
			result[k] = value[i]

		return result


	translateMap: (list, count = null, args = {}, base = null) ->
		type = Object.prototype.toString.call(list)
		if type not in ['[object Array]', '[object Object]']
			throw new Error 'Translate map is only for arrays and objects.'

		params = Args(arguments, [Args.oneOf([Args.array, Args.object]), Args.number(null), Args.object({}), Args.string(null)])
		list = params[0]
		count = params[1]
		args = params[2]
		base = params[3]

		base = if base != null then base + '.' else ''

		if type == '[object Array]'
			for m, i in list
				list[i] = @translate(base + m, count, args)

		else
			for k, m of list
				list[k] = @translate(base + m, count, args)

		return list


	isList: (translation) ->
		return Object.prototype.toString.call(translation[0]) == '[object Array]'


	pluralize: (message, translation, count = null, language = @language) ->
		if count != null
			if typeof translation[0] == 'string'
				pluralForm = 'n=' + count + ';plural=+(' + @plurals[language].form + ');'

				n = null
				plural = null

				eval(pluralForm)

				message = if plural != null && typeof translation[plural] != 'undefined' then translation[plural] else translation[0]
			else
				result = []
				result.push(@pluralize(message, t, count, language)) for t in translation
				message = result
		else
			if typeof translation[0] == 'string'
				message = translation[0]
			else
				message = []
				message.push(t[0]) for t in translation

		return message


	prepareTranslation: (message, args = {}) ->
		if typeof message == 'string'
			message = @applyReplacements(message, args)
		else
			result = []
			for m in message
				result.push(@prepareTranslation(m, args))
			message = result

		return message


	applyReplacements: (message, args = {}) ->
		replacements = @replacements

		for name, value of args
			replacements[name] = value

		for name, value of replacements
			if value != false
				pattern = new RegExp('%' + name + '%', 'g')
				message = message.replace(pattern, value)

		return message


	getMessageInfo: (message) ->
		num = message.lastIndexOf('.')
		_path = message.substr(0, num)
		name = message.substr(num + 1)
		num = _path.lastIndexOf('.')
		category = _path.substr(num + 1)
		_path = _path.substr(0, num).replace(/\./g, '/')
		result =
			path: _path
			category: category
			name: name
		return result


module.exports = Translator