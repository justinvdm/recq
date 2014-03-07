fs = require 'fs'
assert = require 'assert'
nock = require 'nock'
tmp = require 'tmp'
recq = require './recq'

describe "recq", ->
  filepath = null

  header = (req, name) -> req._headers[name]

  beforeEach (done) ->
    nock.cleanAll()

    tmp.tmpName postfix: '.json', (err, path) ->
      filepath = path
      done()

  describe "the request", ->
    it "should use basic auth if given", (done) ->
      nock('http://foo.com')
        .get('/')
        .reply(200)

      recq
        file: filepath
        url: 'http://foo.com/'
        auth: 'foo:bar'
        done: (opts) ->
          assert.equal(
            header(opts.res.req, 'authorization'),
            "Basic Zm9vOmJhcg==")
          done()

    it "should use the request data if given", (done) ->
      nock('http://foo.com')
        .get('/', {foo: 'bar'})
        .reply(200)

      recq
        file: filepath
        url: 'http://foo.com/'
        data: '{"foo":"bar"}'
        done: -> done()

    it "should set the given content type", (done) ->
      nock('http://foo.com')
        .get('/', {foo: 'bar'})
        .reply(200)

      recq
        file: filepath
        url: 'http://foo.com/'
        data: '{"foo":"bar"}'
        type: 'text/plain'
        done: (opts) ->
          assert.equal(
            header(opts.res.req, 'content-type'),
            'text/plain')
          done()

    it "should use the given request method", (done) ->
      nock('http://foo.com')
        .head('/')
        .reply(200)

      recq
        file: filepath
        url: 'http://foo.com/'
        method: 'head'
        done: -> done()

  describe "the output", ->
    it "should store the raw request data for non-json requests", (done) ->
      nock('http://foo.com')
        .get('/bar', 'lerp')
        .reply(200)

      check = ->
        [data] = require(filepath)
        assert 'data' not in data.request
        assert.equal data.request.body, 'lerp'
        done()

      recq
        file: filepath
        url: 'http://foo.com/bar'
        data: 'lerp'
        type: 'text/plain'
        done: -> check()

    it "should store the decoded request data for json requests", (done) ->
      nock('http://foo.com')
        .get('/bar', {lerp: 'larp'})
        .reply(200)

      check = ->
        [data] = require(filepath)
        assert 'data' not in data.request
        assert.deepEqual data.request.data, {lerp: 'larp'}
        done()

      recq
        file: filepath
        url: 'http://foo.com/bar'
        data: '{"lerp":"larp"}'
        done: -> check()

    it "should store the raw response data for non-json requests", (done) ->
      nock('http://foo.com')
        .get('/bar')
        .reply(200, 'lamb')

      check = ->
        [data] = require(filepath)
        assert 'data' not in data.response
        assert.equal data.response.body, 'lamb'
        done()

      recq
        file: filepath
        url: 'http://foo.com/bar'
        type: 'text/plain'
        done: -> check()

    it "should store the decoded response data for json requests", (done) ->
      nock('http://foo.com')
        .get('/bar')
        .reply(200, {lamb: 'sham'})

      check = ->
        [data] = require(filepath)
        assert 'body' not in data.response
        assert.deepEqual data.response.data, {lamb: 'sham'}
        done()

      recq
        file: filepath
        url: 'http://foo.com/bar'
        done: -> check()

    it "should store the data to an array if no key is given", (done) ->
      nock('http://foo.com')
        .get('/bar', {spam: 'ham'})
        .reply(200, {lamb: 'sham'})

      nock('http://foo.com')
        .put('/baz', {lerp: 'larp'})
        .reply(201, {lorem: 'lark'})

      a = ->
        recq
          file: filepath
          url: 'http://foo.com/bar'
          data: '{"spam":"ham"}'
          done: -> b()

      b = ->
        recq
          file: filepath
          url: 'http://foo.com/baz'
          method: 'put'
          data: '{"lerp":"larp"}'
          done: -> check()

      check = ->
        data = require(filepath)
        assert.deepEqual data, [
          request:
            method: 'GET'
            url: 'http://foo.com/bar'
            data: {spam: 'ham'}
          response:
            code: 200
            data: {lamb: 'sham'}
        ,
          request:
            method: 'PUT'
            url: 'http://foo.com/baz'
            data: {lerp: 'larp'}
          response:
            code: 201
            data: {lorem: 'lark'}]
        done()

      a()

    it "should store the data to an object if a key is given", (done) ->
      nock('http://foo.com')
        .get('/bar', {spam: 'ham'})
        .reply(200, {lamb: 'sham'})

      nock('http://foo.com')
        .put('/baz', {lerp: 'larp'})
        .reply(201, {lorem: 'lark'})

      a = ->
        recq
          key: 'bar'
          file: filepath
          url: 'http://foo.com/bar'
          data: '{"spam":"ham"}'
          done: -> b()

      b = ->
        recq
          key: 'baz'
          file: filepath
          url: 'http://foo.com/baz'
          method: 'put'
          data: '{"lerp":"larp"}'
          done: -> check()

      check = ->
        data = require(filepath)
        assert.deepEqual data,
          bar:
            request:
              method: 'GET'
              url: 'http://foo.com/bar'
              data: {spam: 'ham'}
            response:
              code: 200
              data: {lamb: 'sham'}
          baz:
            request:
              method: 'PUT'
              url: 'http://foo.com/baz'
              data: {lerp: 'larp'}
            response:
              code: 201
              data: {lorem: 'lark'}
        done()

      a()

    it "should throw an error if a key is given but storage is an array", ->
      fs.writeFileSync(filepath, '[]')

      assert.throws ->
        recq
          key: 'bar'
          file: filepath
          url: 'http://foo.com/bar'
          data: '{"spam":"ham"}'

    it "should throw an error if no key is given but storage is an object", ->
      fs.writeFileSync(filepath, '{}')

      assert.throws ->
        recq
          file: filepath
          url: 'http://foo.com/bar'
          data: '{"spam":"ham"}'
