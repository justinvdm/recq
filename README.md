# recq
Record requests to a json file. Useful for recording api requests (possibly for use as fixtures).

```sh
$ recq -u http://foo.com -d {"bar":"baz"}
```

```javascript
[
  {
    "request": {
      "method": "GET",
      "url": "http://foo.com",
      "body": {
        "bar": "baz"
      }
    },
    "response": {
      "code": 200,
      "body": {
        "lerp": "larp"
      }
    }
  },
]
```

## Usage

```sh
$ npm install -g recq
$ recq --help

  Usage: recq.coffee [options] <url>

  Options:

    -h, --help                        output usage information
    -m, --method <method>             The http request method to use
    -f, --file <file>                 The storage file to use
    -k, --key <key>                   The key to use for the datum in the file
    -d, --data <data>                 Request body data
    -a, --auth <username>:<password>  Basic auth
    --nojson                          If this is not a json request
```
