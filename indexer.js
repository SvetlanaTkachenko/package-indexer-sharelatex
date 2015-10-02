(function() {
  var Indexer, args, fs, result, result_json,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  fs = require('fs');

  Indexer = {
    build: function() {
      var index;
      index = {
        indexBuiltAt: new Date().toISOString(),
        packages: {
          python: {},
          r: {}
        }
      };
      return index;
    }
  };

  args = process.argv.slice(2);

  result = Indexer.build();

  if (__indexOf.call(args, '--save') >= 0) {
    result_json = JSON.stringify(result, null, 2);
    fs.writeFileSync(__dirname + '/data/packageIndex.json', result_json);
  }

  console.log(result);

}).call(this);
