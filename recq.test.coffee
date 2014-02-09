fs = require 'fs'
assert = require 'assert'
nock = require 'nock'
base64 = require 'base64'
tmp = require 'tmp'
recq = require 'recq'

describe "recq", ->
  run = (cmd, done) ->
    args = ['node', 'recq'].concat(cmd.split(' '))
    recq.run(args, done)

  header = (req, name) -> req._headers[name]

  beforeEach ->
    nock.cleanAll()

  describe "the request", ->
    it "should use basic auth if given", (done) ->
      nock('http://foo.com').get('/').reply(200)

      run '-u http://foo.com/ -a foo:bar', (res) ->
        assert.equal(
          header(res.req, 'authorization'),
          "Basic #{base64.encode('foo:bar')}")
        done()

    it "should use the request body if given", (done) ->
      nock('http://foo.com').get('/', {foo: 'bar'}).reply(200)
      run '-u http://foo.com/ -d {"foo":"bar"}', -> done()

    it "should set the content type to json if relevant", (done) ->
      nock('http://foo.com').get('/', {foo: 'bar'}).reply(200)

      run '-u http://foo.com/ -d {"foo":"bar"}', (res) ->
        assert.equal(
          header(res.req, 'content-type'),
          'application/json')
        done()

    it "should not set the content type to json if not relevant", (done) ->
      nock('http://foo.com').get('/').reply(200)

      run '-u http://foo.com/ --nojson', (res) ->
        assert(typeof header(res.req, 'content-type') is 'undefined')
        done()

    it "should use the given request method", (done) ->
      nock('http://foo.com').head('/').reply(200)
      run '-u http://foo.com/ -m head', -> done()

  describe "the output", ->
    it "should append the recorded data to the data file", (done) ->
      nock('http://foo.com')
        .get('/bar', {spam: 'ham'})
        .reply(200, {lamb: 'sham'})

      nock('http://foo.com')
        .put('/baz', {lerp: 'larp'})
        .reply(201, {lorem: 'lark'})

      tmp.file postfix: '.json', (err, path) ->
        fs.writeFileSync(path, '[]')

        run "-u http://foo.com/bar -d #{'{"spam":"ham"}'} -f #{path}", ->
          run "-m put -u http://foo.com/baz -d #{'{"lerp":"larp"}'} -f #{path}", ->
            data = require(path)
            assert.deepEqual data, [{
                request:
                  method: 'GET'
                  url: 'http://foo.com/bar'
                  body: {spam: 'ham'}
                response:
                  code: 200
                  body: {lamb: 'sham'}
            }, {
                request:
                  method: 'PUT'
                  url: 'http://foo.com/baz'
                  body: {lerp: 'larp'}
                response:
                  code: 201
                  body: {lorem: 'lark'}
            }]
            done()
