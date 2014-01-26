Loader = require './Loader'
path = require '../node/path'

isWindow = typeof window != 'undefined'

if !isWindow
	callsite = require 'callsite'

class Json extends Loader


	directory: '/app/lang'


	constructor: (@directory = @directory) ->
		if @directory.charAt(0) == '.' && isWindow
			throw new Error 'Relative paths to dictionaries is not supported in browser.'

		if @directory.charAt(0) == '.'
			stack = callsite()
			@directory = path.dirname(stack[1].getFileName())

		if !isWindow
			@directory = path.normalize(@directory)


	load: (parent, name, language) ->
		_path = @getFileSystemPath(parent, name, language)
		try data = require(_path) catch e then data = {}
		return data


	getFileSystemPath: (parent, name, language) ->
		return @directory + (if parent != '' then '/' + parent else '') + "/#{language}.#{name}.json"


module.exports = Json