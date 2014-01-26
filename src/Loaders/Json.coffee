Loader = require './Loader'
path = require '../node/path'

isBrowser = typeof window != 'undefined'

if !isBrowser
	callsite = require 'callsite'
	fs = require 'fs'

class Json extends Loader


	directory: '/app/lang'


	constructor: (@directory = @directory) ->
		if @directory.charAt(0) == '.' && isBrowser
			throw new Error 'Relative paths to dictionaries is not supported in browser.'

		if @directory.charAt(0) == '.'
			stack = callsite()
			@directory = path.dirname(stack[1].getFileName())

		if !isBrowser
			@directory = path.normalize(@directory)


	load: (parent, name, language) ->
		_path = @getFileSystemPath(parent, name, language)
		try data = require(_path) catch e then data = {}
		return data


	getFileSystemPath: (parent, name, language) ->
		return @directory + (if parent != '' then '/' + parent else '') + "/#{language}.#{name}.json"


module.exports = Json