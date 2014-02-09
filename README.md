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

  Usage: recq.coffee [options]

  Options:

    -h, --help                        output usage information
    -m, --method <method>             The http request method to use
    -u, --url <url>                   The url to hit
    -f, --file <file>                 Where the file should be saved
    -s, --save                        Whether the request and response should be saved
    -a, --auth <username>:<password>  Basic auth
    -d, --data <data>                 Request body data
    --nojson                          If this is not a json request
```
