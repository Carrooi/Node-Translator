Loader = require './Loader'

class Json extends Loader


	directory: '/app/lang'


	constructor: (@directory = @directory) ->


	load: (parent, name, language) ->
		path = @getFileSystemPath(parent, name, language)
		try data = require(path) catch e then data = {}
		return data


	getFileSystemPath: (parent, name, language) ->
		return @directory + (if parent != '' then '/' + parent else '') + "/#{language}.#{name}.json"


module.exports = Json