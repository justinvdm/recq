// Generated by CoffeeScript 1.7.1
(function() {
  var defaults, fs, log, nurl, parse, path, pkg, read, recq, request, run, serialize, write, _;

  fs = require('fs');

  nurl = require('url');

  path = require('path');

  _ = require('underscore');

  request = require('superagent');

  pkg = require('./package');

  recq = require('commander');

  recq.version(pkg.version).usage("[options] <url>").option('-m, --method <method>', "The http request method to use").option('-f, --file <file>', "The storage file to use").option('-k, --key <key>', "The key to use for the datum in the file if the file is a json object").option('-d, --data <data>', "Request body data").option('-a, --auth <username>:<password>', "Basic auth").option('-t, --type <type>', "The type of the request. May be any value allowed by superagent.");

  defaults = {
    method: 'GET',
    file: './data.json',
    type: 'json'
  };

  run = function(opts) {
    var req, url, urlParts;
    opts = parse(opts);
    urlParts = nurl.parse(opts.url);
    url = nurl.format(_.omit(urlParts, 'query', 'search'));
    req = request(opts.method, url);
    if (opts.username != null) {
      req.auth(opts.username, opts.password);
    }
    if (urlParts.query != null) {
      req.query(urlParts.query);
    }
    req.type(opts.type);
    if (opts.data) {
      req.send(opts.data);
    }
    req.buffer();
    return req.end(function(res) {
      opts.res = res;
      log(opts);
      write(opts);
      if (opts.done != null) {
        return opts.done(opts);
      }
    });
  };

  parse = function(opts) {
    var _ref;
    opts = _({}).extend(defaults, opts);
    if (opts.type === 'application/json') {
      opts.type = 'json';
    }
    opts.file = path.resolve(opts.file);
    opts.method = opts.method.toUpperCase();
    if (opts.type === 'json' && opts.data) {
      opts.data = JSON.parse(opts.data);
    }
    if (opts.auth) {
      _ref = opts.auth.split(':'), opts.username = _ref[0], opts.password = _ref[1];
    }
    opts.store = read(opts);
    return opts;
  };

  read = function(opts) {
    var store;
    if (fs.existsSync(opts.file)) {
      store = require(opts.file);
      if (opts.key && _(store).isArray()) {
        throw new Error("Key '" + opts.key + "' specified, but storage file is an array");
      }
      if (!opts.key && !_(store).isArray()) {
        throw new Error("No key specified, but storage file is not an array");
      }
      return store;
    } else if (opts.key) {
      return {};
    } else {
      return [];
    }
  };

  write = function(opts) {
    var d;
    d = serialize(opts);
    if (opts.key) {
      opts.store[opts.key] = d;
    } else {
      opts.store.push(d);
    }
    return fs.writeFileSync(opts.file, JSON.stringify(opts.store, null, 2));
  };

  serialize = function(opts) {
    return {
      request: serialize.req(opts),
      response: serialize.res(opts)
    };
  };

  serialize.req = function(opts) {
    var d;
    d = {
      method: opts.method,
      url: opts.url
    };
    if (opts.type === 'json') {
      d.data = opts.data;
    } else {
      d.body = opts.data;
    }
    return d;
  };

  serialize.res = function(opts) {
    var d;
    d = {
      code: opts.res.statusCode
    };
    if (opts.type === 'json') {
      d.data = opts.res.body;
    } else {
      d.body = opts.res.text;
    }
    return d;
  };

  log = function(opts) {
    if (require.main === module) {
      return console.log("(" + opts.res.status + ") " + opts.res.text);
    }
  };

  if (require.main === module) {
    recq.parse(process.argv);
    recq.url = recq.args[0];
    run(recq);
  }

  module.exports = run;

}).call(this);
