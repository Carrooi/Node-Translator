class Loader


	load: ->
		throw new Error 'Translator loader: you have to implement method load.'


	getFileSystemPath: ->
		throw new Error 'Translator loader: you have to implement method getFileSystemPath.'


module.exports = Loader