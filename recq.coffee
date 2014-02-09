#!/usr/bin/env coffee

fs = require 'fs'
nurl = require 'url'
path = require 'path'
request = require 'superagent'
commander = require 'commander'

cmd = (args) ->
  new commander.Command()
    .option('-m, --method <method>', "The http request method to use", 'GET')
    .option('-u, --url <url>', "The url to hit")
    .option('-f, --file <file>', "Where the file should be saved", './data.json')
    .option('-a, --auth <username>:<password>', "Basic auth")
    .option('-d, --data <data>', "Request body data")
    .option('--nojson', "If this is not a json request")
    .parse(args)

serialize = (recq, res) ->
  request: serialize.req(recq)
  response: serialize.res(res)

serialize.req = (recq) ->
  d =
    method: recq.method
    url: recq.url

  d.body = recq.data if recq.data
  return d

serialize.res = (res) ->
  d = code: res.statusCode
  d.body = res.body if res.body
  return d

save = (recq, res, data) ->
  d = serialize(recq, res)
  data.push(d)
  fs.writeFileSync(recq.file, JSON.stringify(data, null, 2))

parse = (recq) ->
  recq.json = not recq.nojson
  [recq.username, recq.password] = recq.auth.split(':') if recq.auth
  recq.method = recq.method.toUpperCase()
  recq.data = JSON.parse(recq.data) if recq.data and recq.json
  recq.file = path.resolve(recq.file)

log = (recq, res) ->
  if require.main is module
    console.log("(#{res.status}) #{res.text}")

run = (args, done) ->
  recq = cmd(args)
  parse(recq)

  if fs.existsSync(recq.file)
    data = require(recq.file)
  else
    data = []

  req = request(recq.method, recq.url)
  req.auth(recq.username, recq.password) if recq.username?
  req.type('application/json') if req.json
  req.send(recq.data) if recq.data

  req.end (res) ->
    log(recq, res)
    save(recq, res, data)
    done(res) if done?

exports.run = run
run(process.argv) if require.main is module
