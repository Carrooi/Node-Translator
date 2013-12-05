# translator

Node translator with plural forms support. Works also in browser (for example with [simq](https://npmjs.org/package/simq)).

This package is compatible with [translator](https://packagist.org/packages/sakren/translator) for PHP.

## Installation

```
$ npm install translator
```

## Dictionary files

This translator supposed to be translator working with key -> translation principe. For easier manipulation, you can have
many smaller dictionaries for smaller group of translations.

These dictionaries are json files with language code on the beginning. Below is example of few files.

```
/app/lang/homepage/en.menu.json
/app/lang/homepage/promo/en.box.json
/app/lang/en.about.json
```

There we have got three dictionaries, two for homepage and one for about page, but these names are totally up to you.

## Dictionary

Here is example of /app/lang/homepage/promo/en.box.json dictionary.

```
{
	"title": "Promo box",
	"description": "some description",
	"text": "and some really long text",
	"someOtherTextToDisplay": "other boring text"
}
```

This is the most simple example of dictionary (and most stupid). Again these translation's names are up to you.

## Usage

When you have got your dictionaries, you can setup translator and start using it.

```
var Translator = require('translator');
var translator = new Translator('/app/lang');

translator.language = 'en';

var message = translator.translate('homepage.promo.box.text');		// output: and some really long text
```

You have to set language, and base directory path. Be careful with this, because if you set relative path, then it will
be relative to Translator class. Translator using require function for loading dictionaries, so it not depends on fs module
and can be used also on browser.

Then you can begin with translating. You can see that messages to translate are paths to your dictionary files but with
dots instead of slashes and without language code.

## Plural forms

There is already registered 138 plural forms and you can find list of them on [this](http://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html)
site. If you will miss some language, wrote issue or register it by your own.

First you have to set plural forms rule for language which you want to use. This is little javascript code which will
be called every time, you want to use plural forms and will decide which plural form should be used.

```
translator.addPluralForm(
	'en',				// language code
	2,					// total count of plural forms for this language
	'(n===1) ? 0 : 1'	// decision code. In "n" variable is count of items and it says that if it is 1 item, first (0) form will be used, otherwise second form
);
```

For comparing, here is example of czech plural forms.

```
translator.addPluralForm(
	'cs',
	3,
	'(n===0) ? 2 : ((n===1) ? 0 : ((n>=2 && n<=4) ? 1 : 2))'
);
```

Now we have to add plural forms to our dictionary. (/app/lang/homepage/promo/en.box.json)

```
{
	"cars": [
		"1 car",
		"%count% cars"
	]
}
```

%count% will be automatically replaced with count of items. Again for comparing czech version. (/app/lang/homepage/promo/cs.box.json)

```
{
	"cars": [
		"1 auto",
		"%count% auta",
		"%count% aut"
	]
}
```

And now you can finally use it.

```
var message = translator.translate('homepage.promo.box.cars', 2);		// output: 2 cars
```

## Replacements

%count% is the base example of replacements, but you can create others. For example you can set replacement for %site%
and then it will be automatically changed to name of your site, so if you will change it in future, you will change it only
in one place.

Dictionary:

```
{
	"info": "web site name: %site%"
}
```

Usage:

```
translator.addReplacement('site', 'my-site-name.com');

var message = translator.translate('dictionary.info');		// output: web site name: my-site-name.com
```

This is example of persistent replacements, but you can create independent replacements for each translation.

Dictionary:

```
{
	"info": "display some random variable: %something%"
}
```

Usage:

```
var message = translator.translate('dictionary.info', null, {		// output: display some random variable: 2 books
	something: '2 books'
});
```

if you do not need to pass any count (like in example above), you can remove second argument (null).

```
var message = translator.translate('dictionary.info', {		// output: display some random variable: 2 books
	something: '2 books'
});
```

### In names of translations

These replacements can be used also in message names. This is quite useful when you have got for example different user
roles with different translations. Then you can set replacement with name `role` and save these translations into
different directories.

en.admin.json:

```
{
	"title": "Page for admin"
}
```

en.normal.json:

```
{
	"title": "Page for normal user"
}
```

Usage:

```
translator.addReplacement('role', user.getRole());
translator.translate('admin.%role%');
```

## List of translations

Sometimes you may want to display list of texts but don't want to create translations with these names: item1, item2,
item3 and so on. What if you will want to add some other? This is not the good idea.

But you can create lists in your dictionary and translator will return array of translations.

Dictionary:

```
{
	"someList": [
		["1st item"],
		["2nd item"],
		["3rd item"],
		["4th item"]
	]
}
```

Usage:

```
var messages = translator.translate('dictionary.someList');		// output: [ 1st item, 2nd item, 3rd item, 4th item ]
```

And you can also use it with plural forms.

Dictionary:

```
{
	"fruits": [
		[
			"1 orange",
			"%count% oranges"
		],
		[
			"1 banana",
			"%count% bananas"
		]
	]
}
```

Usage:

```
var messages = translator.translate('dictionary.fruits', 6);		// output: [ 6 oranges, 6 bananas ]
```

### Accessing exact item

```
var message = translator.translate('dictionary.someList[0]');		// output: 1st item
```

### Shorter syntax

If your list contains just singular forms translations, you can use shorter syntax for it.

```
{
	"-- myList": [
		"first item",
		"second item",
		"third item"
	]
}
```

## List of pairs

If you have got one list of for example titles or headlines and other list with texts for these titles, you can let this
translator to automatically combine these two lists together into object.

Dictionary:

```
{
	"titles": [
		["first"],
		["second"]
	],
	"texts": [
		["text for first title"]
		["text for second title"]
	]
}
```

Usage:

```
translator.translatePairs('dictionary', 'titles', 'texts');
```

Output:

```
{
	first: 'text for first title',
	second: 'text for second title'
}
```

## Translate whole array or object

When you have got some array, which you need to translate, you don't have to iterate through it yourself.

```
var messages = [
	'homepage.promo.box.title',
	'homepage.promo.box.description',
	'homepage.promo.box.text'
];

var result = translator.translateMap(messages);
```

This can be also used for literal objects.

If your array to translate contains translations just from one dictionary, you can set some kind of base path.

```
var messages = [
	'title',
	'description',
	'text'
];

var result = translator.translateMap(messages, 'homepage.promo.box.title');
```

Or use count for translations with plural forms.

```
var result = translator.translateMap(messages, 6);
```

Or with some replacements.

```
var result = translator.translateMap(messages, {type: 'book'});
```

Of course you can pass any argument you need, you only have to keep the right order of arguments (uses [normalize-arguments](https://npmjs.org/package/normalize-arguments)):

```
translator.translateMap(arrayOrObjectToTranslate, countForPluralForms, objectWithReplacements, basePathString);
```

## Comments in dictionaries

You can write some comments into your dictionaries. These comments has to be enclosed into `#`.

```
{
	"message": [
		"# this message will be displayed in home page #",
		 "translation of message"
	]
}
```

Or with lists:

```
{
	"list": [
		"# this is list of some items #",
		[
			"# first item in list #",
			"first"
		],
		[
			"# second item in list #",
			"second"
		]
	]
}
```

## Caching

Turning on cache will make loading your dictionaries faster. They don't need to be parsed in any way, because parsed version
is already in cache.

This translator uses [cache-storage](https://npmjs.org/package/cache-storage) package.

```
var FileStorage = require('cache-storage/Storage/FileStorage');

translator.setCacheStorage(new FileStorage('./path/to/cache/directory'));
```

Unfortunately now there is no way to use caching in browser.

## Tests

```
$ npm test
```

There are also tests for browser, but because of this strange [bug](https://github.com/metaskills/mocha-phantomjs/issues/105),
they will fail. If you want to run them, you have to open `./test/browser/index.html` file in your browser.

## Changelog

* 1.7.2
	+ Bug with dictionaries in root

* 1.7.1
	+ Tests were broken
	+ Updated modules

* 1.7.0
	+ Removed version tag from dictionaries (bc break)
	+ Better caching with [simq](https://npmjs.org/package/simq) in browser
	+ Added tests for browser
	+ Many optimizations

* 1.6.1
	+ Uses [normalize-arguments](https://npmjs.org/package/normalize-arguments) for translate method

* 1.6.0
	+ Refactoring tests
	+ Optimized dependencies
	+ Added method translateMap

* 1.5.0
	+ Accessing items from lists in translate method
	+ Using chai instead of should for tests

* 1.4.4
	+ Translate method: can pass args as second argument

* 1.4.3
	+ Bug with cache in browser

* 1.4.1 - 1.4.2
	+ Optimized plural forms

* 1.4.0
	+ Support for comments in dictionaries
	+ Shorter syntax for lists
	+ Support for caching with [cache-storage](https://npmjs.org/package/cache-storage)
	+ Tests rewritten into coffee script

* 1.3.1
	+ Replacements in messages

* 1.3.0
	+ Added some tests
	+ Added method translatePairs

* 1.2.3
	+ Added some test
	+ Potential bug fix
	+ Directory can be set in constructor
	+ Some typos in readme

* 1.2.2
	+ Added just some keyword
	+ New test reporter

* 1.2.1
	+ Added all other changes to changelog

* 1.2.0
	+ Created changelog list
	+ Added tests
	+ Tests can be run with `npm test` command
	+ Repaired some bugs

* 1.1.1
	+ Prepared for tests
	+ Removed forgotten debug code

* 1.1.0
	+ Added plural forms from [translatehouse.org](http://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html) site

* 1.0.2
	+ Added MIT license

* 1.0.1
	+ Corrected some mistakes in readme
	+ Removed unnecessary dependencies

* 1.0.0
	+ Initial commit