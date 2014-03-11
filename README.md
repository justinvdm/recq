# recq
Record requests to a json file. Useful for recording api requests (possibly for use as fixtures).

```sh
$ recq -k foo -d '{"bar":"baz"}' http://foo.com 
```

```javascript
{
  "foo": {
    "request": {
      "method": "GET",
      "url": "http://foo.com",
      "data": {
        "bar": "baz"
      }
    },
    "response": {
      "code": 200,
      "data": {
        "lerp": "larp"
      }
    }
  }
}
```

## Usage

```sh
$ recq --help

  Usage: recq.coffee [options] <url>

  Options:

    -h, --help                        output usage information
    -V, --version                     output the version number
    -m, --method <method>             The http request method to use
    -f, --file <file>                 The storage file to use
    -k, --key <key>                   The key to use for the datum in the file if the file is a json object
    -d, --data <data>                 Request body data
    -a, --auth <username>:<password>  Basic auth
    -t, --type <type>                 The type of the request. May be any value allowed by superagent.
```
