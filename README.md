# translator

Node translator with plural forms support. Works also in browser.

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
var translator = new Translator;

translator.language = 'en';
translator.directory = '/app/lang';

var message = translator.translate('homepage.promo.box.text');		// output: and some really long text
```

You have to set language, and base directory path. Be carefull with this, because if you set relative path, then it will
be relative to Translator class. Translator using require function for loading dictionaries, so it not depends on fs module
and can be used also on browser (for example with [simq](https://npmjs.org/package/simq)).

Then you can begin with translating. You can see that messages to translate are paths to your dictionary files but with
dots instead of slashes and without language code.

## Plural forms

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
var message = translator.translate('dictionary.info', {		// output: display some random variable: 2 books
	somethins: '2 books'
});
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