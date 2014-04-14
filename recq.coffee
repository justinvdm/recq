#!/usr/bin/env coffee

fs = require 'fs'
nurl = require 'url'
path = require 'path'
_ = require 'underscore'
request = require 'superagent'
recq = require 'commander'


recq
  .version '0.2.2'

  .usage "[options] <url>"

  .option '-m, --method <method>',
    "The http request method to use"

  .option '-f, --file <file>',
    "The storage file to use"

  .option '-k, --key <key>',
    "The key to use for the datum in the file if the file is a json object"

  .option '-d, --data <data>',
    "Request body data"

  .option '-a, --auth <username>:<password>',
    "Basic auth"

  .option '-t, --type <type>',
    "The type of the request. May be any value allowed by superagent."


defaults =
  method: 'GET'
  file: './data.json'
  type: 'json'


run = (opts) ->
  opts = parse(opts)

  urlParts = nurl.parse(opts.url)
  url = nurl.format(_.omit(urlParts, 'query', 'search'))

  req = request(opts.method, url)
  req.auth(opts.username, opts.password) if opts.username?
  req.query(urlParts.query) if urlParts.query?
  req.type(opts.type)
  req.send(opts.data) if opts.data
  req.buffer()

  req.end (res) ->
    opts.res = res
    log(opts)
    write(opts)
    opts.done(opts) if opts.done?


parse = (opts) ->
  opts = _({}).extend(defaults, opts)
  opts.type = 'json' if opts.type == 'application/json'

  opts.file = path.resolve(opts.file)
  opts.method = opts.method.toUpperCase()
  opts.data = JSON.parse(opts.data) if opts.type == 'json' and opts.data
  [opts.username, opts.password] = opts.auth.split(':') if opts.auth
  opts.store = read(opts)

  return opts


read = (opts) ->
  if fs.existsSync(opts.file)
    store = require(opts.file)

    if opts.key and _(store).isArray()
      throw new Error "Key '#{opts.key}' specified, but storage file is an array"

    if not opts.key and not _(store).isArray()
      throw new Error "No key specified, but storage file is not an array"

    store
  else if opts.key
    {}
  else
    []


write = (opts) ->
  d = serialize(opts)

  if opts.key
    opts.store[opts.key] = d
  else
    opts.store.push(d)

  fs.writeFileSync(opts.file, JSON.stringify(opts.store, null, 2))


serialize = (opts) ->
  request: serialize.req(opts)
  response: serialize.res(opts)


serialize.req = (opts) ->
  d =
    method: opts.method
    url: opts.url

  if opts.type == 'json'
    d.data = opts.data
  else
    d.body = opts.data

  return d


serialize.res = (opts) ->
  d = code: opts.res.statusCode

  if opts.type == 'json'
    d.data = opts.res.body
  else
    d.body = opts.res.text

  return d


log = (opts) ->
  if require.main is module
    console.log("(#{opts.res.status}) #{opts.res.text}")


if require.main is module
  recq.parse(process.argv)
  recq.url = recq.args[0]
  run(recq)


module.exports = run
