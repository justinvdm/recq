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
