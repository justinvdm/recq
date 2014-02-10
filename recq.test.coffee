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

    it "should use the request body if given", (done) ->
      nock('http://foo.com')
        .get('/', {foo: 'bar'})
        .reply(200)

      recq
        file: filepath
        url: 'http://foo.com/'
        data: '{"foo":"bar"}'
        done: -> done()

    it "should set the content type to json if relevant", (done) ->
      nock('http://foo.com')
        .get('/', {foo: 'bar'})
        .reply(200)

      recq
        file: filepath
        url: 'http://foo.com/'
        data: '{"foo":"bar"}'
        done: (opts) ->
          assert.equal(
            header(opts.res.req, 'content-type'),
            'application/json')
          done()

    it "should not set the content type to json if not relevant", (done) ->
      nock('http://foo.com')
        .get('/')
        .reply(200)

      recq
        file: filepath
        url: 'http://foo.com/'
        nojson: true,
        done: (opts) ->
          assert(typeof header(opts.res.req, 'content-type') is 'undefined')
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
            body: {spam: 'ham'}
          response:
            code: 200
            body: {lamb: 'sham'}
        ,
          request:
            method: 'PUT'
            url: 'http://foo.com/baz'
            body: {lerp: 'larp'}
          response:
            code: 201
            body: {lorem: 'lark'}]
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
              body: {spam: 'ham'}
            response:
              code: 200
              body: {lamb: 'sham'}
          baz:
            request:
              method: 'PUT'
              url: 'http://foo.com/baz'
              body: {lerp: 'larp'}
            response:
              code: 201
              body: {lorem: 'lark'}
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
