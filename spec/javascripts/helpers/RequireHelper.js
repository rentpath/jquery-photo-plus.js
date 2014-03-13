// Generated by CoffeeScript 1.7.1
var _describe, _it;

_it = window.it;

_describe = window.describe;

window.zutron_host = 'http://172.20.52.55';

window.ONESEARCH_URL = "http://onesearch01.ci.primedia.com:8080";

window.it = function(description, depsOrTestFn, testFn) {
  if (arguments.length === 1) {
    return window.xit.call(this, description);
  } else if (arguments.length === 3) {
    return _it(description, function() {
      var jasmineContext, readyModules;
      jasmineContext = this;
      readyModules = [];
      waitsFor(function() {
        require(depsOrTestFn, function() {
          return readyModules = arguments;
        });
        return readyModules.length === depsOrTestFn.length;
      });
      return runs(function() {
        var arrayOfModules;
        arrayOfModules = void 0;
        arrayOfModules = Array.prototype.slice.call(readyModules);
        return testFn.apply(jasmineContext, arrayOfModules);
      });
    });
  } else {
    return _it.apply(this, [description, depsOrTestFn]);
  }
};

window._onload = window.onload;

window.onload = function() {};

window._describeCount = 0;

window.describe = function(description, depsOrTestFn, testFn) {
  var readyModules;
  if (arguments.length === 1) {
    return window.xdescribe.call(this, description);
  } else if (arguments.length === 3) {
    _describeCount++;
    readyModules = [];
    return require(depsOrTestFn, function() {
      readyModules = arguments;
      _describe(description, function() {
        testFn.apply(this, readyModules);
        return _describeCount--;
      });
      if (_describeCount <= 0) {
        return _onload();
      }
    });
  } else {
    return _describe.call(this, description, depsOrTestFn);
  }
};
