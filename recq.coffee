#!/usr/bin/env coffee

fs = require 'fs'
nurl = require 'url'
path = require 'path'
_ = require 'underscore'
request = require 'superagent'
recq = require 'commander'


recq
  .usage "[options] <url>"

  .option '-m, --method <method>',
    "The http request method to use"

  .option '-f, --file <file>',
    "The storage file to use"

  .option '-k, --key <key>',
    "The key to use for the datum in the file"
    "if the file is a json object, not a json array"

  .option '-d, --data <data>',
    "Request body data"

  .option '-a, --auth <username>:<password>',
    "Basic auth"

  .option '--nojson',
    "If this is not a json request"


defaults =
  method: 'GET'
  file: './data.json'


run = (opts) ->
  opts = parse(opts)

  req = request(opts.method, opts.url)
  req.auth(opts.username, opts.password) if opts.username?
  req.type('application/json') if req.json
  req.send(opts.data) if opts.data

  req.end (res) ->
    opts.res = res
    log(opts)
    write(opts)
    opts.done(opts) if opts.done?


parse = (opts) ->
  opts = _({}).extend(defaults, opts)

  opts.json = not opts.nojson
  opts.file = path.resolve(opts.file)
  opts.method = opts.method.toUpperCase()
  opts.data = JSON.parse(opts.data) if opts.data and opts.json
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

  d.body = opts.data if opts.data
  return d


serialize.res = (opts) ->
  d = code: opts.res.statusCode
  d.body = opts.res.body if opts.res.body
  return d


log = (opts) ->
  if require.main is module
    console.log("(#{opts.res.status}) #{opts.res.text}")


if require.main is module
  recq.parse(process.argv)
  recq.url = recq.args[0]
  run(recq)


module.exports = run
