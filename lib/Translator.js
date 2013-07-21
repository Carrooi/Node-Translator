// Generated by CoffeeScript 1.6.3
(function() {
  var Translator;

  Translator = (function() {
    function Translator() {}

    Translator.prototype.directory = '/app/lang';

    Translator.prototype.language = null;

    Translator.prototype.plurals = {};

    Translator.prototype.replacements = {};

    Translator.prototype.data = {};

    Translator.prototype.addPluralForm = function(language, count, form) {
      this.plurals[language] = {
        count: count,
        form: form
      };
      return this;
    };

    Translator.prototype.addReplacement = function(search, replacement) {
      this.replacements[search] = replacement;
      return this;
    };

    Translator.prototype.loadCategory = function(path, name) {
      var categoryName;
      categoryName = path + '/' + name;
      if (typeof this.data[categoryName] === 'undefined') {
        name = path + '/' + this.language + '.' + name;
        this.data[categoryName] = this.normalizeTranslations(require(this.directory + '/' + name));
      }
      return this.data[categoryName];
    };

    Translator.prototype.normalizeTranslations = function(translations) {
      var name, result, translation;
      result = {};
      for (name in translations) {
        translation = translations[name];
        if (typeof translation === 'string') {
          result[name] = [translation];
        } else if (Object.prototype.toString.call(translation) === '[object Array]') {
          result[name] = translation;
        }
      }
      return result;
    };

    Translator.prototype.findTranslation = function(message) {
      var data, info;
      info = this.getMessageInfo(message);
      data = this.loadCategory(info.path, info.category);
      if (typeof data[info.name] === 'undefined') {
        return null;
      } else {
        return data[info.name];
      }
    };

    Translator.prototype.translate = function(message, count, args) {
      var match, translation;
      if (count == null) {
        count = null;
      }
      if (args == null) {
        args = {};
      }
      if (this.language === null) {
        throw new Error('You have to set language');
      }
      if (typeof message !== 'string') {
        return message;
      }
      if ((match = message.match(/^\:(.*)\:$/)) !== null) {
        message = match[1];
      } else {
        translation = this.findTranslation(message);
        if (translation !== null) {
          message = this.pluralize(message, translation, count);
        }
      }
      message = this.prepareTranslation(message, count, args);
      return message;
    };

    Translator.prototype.pluralize = function(message, translation, count) {
      var n, plural, pluralForm, result, t, _i, _j, _len, _len1;
      if (count == null) {
        count = null;
      }
      if (count !== null) {
        if (typeof translation[0] === 'string') {
          pluralForm = 'n=' + count + ';plural=' + this.plurals[this.language].form + ';';
          n = null;
          plural = null;
          eval(pluralForm);
          message = plural !== null && typeof translation[plural] !== 'undefined' ? translation[plural] : translation[0];
        } else {
          result = [];
          for (_i = 0, _len = translation.length; _i < _len; _i++) {
            t = translation[_i];
            result.push(this.pluralize(message, t, count));
          }
          message = result;
        }
      } else {
        if (typeof translation[0] === 'string') {
          message = translation[0];
        } else {
          message = [];
          for (_j = 0, _len1 = translation.length; _j < _len1; _j++) {
            t = translation[_j];
            message.push(t[0]);
          }
        }
      }
      return message;
    };

    Translator.prototype.prepareTranslation = function(message, count, args) {
      var m, name, pattern, replacements, result, value, _i, _len;
      if (count == null) {
        count = null;
      }
      if (args == null) {
        args = {};
      }
      if (typeof message === 'string') {
        replacements = this.replacements;
        if (count !== null) {
          args.count = count;
        }
        for (name in args) {
          value = args[name];
          replacements[name] = value;
        }
        for (name in replacements) {
          value = replacements[name];
          if (value !== false) {
            pattern = new RegExp('%' + name + '%', 'g');
            message = message.replace(pattern, value);
          }
        }
      } else {
        result = [];
        for (_i = 0, _len = message.length; _i < _len; _i++) {
          m = message[_i];
          result.push(this.prepareTranslation(m, count, args));
        }
        message = result;
      }
      return message;
    };

    Translator.prototype.getMessageInfo = function(message) {
      var category, name, num, path, result;
      num = message.lastIndexOf('.');
      path = message.substr(0, num);
      name = message.substr(num + 1);
      num = path.lastIndexOf('.');
      category = path.substr(num + 1);
      path = path.substr(0, num).replace('.', '/');
      result = {
        path: path,
        category: category,
        name: name
      };
      return result;
    };

    return Translator;

  })();

  module.exports = Translator;

}).call(this);