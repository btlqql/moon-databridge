# Request and result guide

Every example below is an executable fixture. Assertions cover the listed result fields; additional output fields are documented by the API and other fixtures. Error cases intentionally reject the request.

## quoted multiline CSV

```json
{
  "format": "csv",
  "text": "id,note\r\n1,\"a,b\"\r\n2,\"line1\nline2\"\r\n"
}
```

Expected result fields:

```json
{
  "rows/0/note": "a,b",
  "rows/1/note": "line1\nline2",
  "input_records": 2
}
```

## typed quarantine

```json
{
  "rows": [
    {
      "n": "7"
    },
    {
      "n": "bad"
    },
    {}
  ],
  "columns": [
    {
      "source": "n",
      "type": "integer",
      "required": true
    }
  ]
}
```

Expected result fields:

```json
{
  "rows/0/n": 7,
  "accepted_before_operations": 1,
  "input_records": 3
}
```

## join filter deduplicate

```json
{
  "rows": [
    {
      "id": 1,
      "n": 3
    },
    {
      "id": 1,
      "n": 3
    },
    {
      "id": 2,
      "n": 0
    }
  ],
  "filter": {
    "field": "n",
    "op": "gt",
    "value": 1
  },
  "deduplicate": [
    "id"
  ],
  "join": {
    "rows": [
      {
        "key": 1,
        "name": "alpha"
      }
    ],
    "left_key": "id",
    "right_key": "key"
  }
}
```

Expected result fields:

```json
{
  "deduplicated": 1,
  "rows/0/right_name": "alpha"
}
```

## group sum mean

```json
{
  "rows": [
    {
      "g": "a",
      "n": 2
    },
    {
      "g": "a",
      "n": 4
    }
  ],
  "group": {
    "keys": [
      "g"
    ],
    "value": "n"
  }
}
```

Expected result fields:

```json
{
  "rows/0/sum": 6,
  "rows/0/mean": 3,
  "rows/0/count": 2
}
```

## JSONL reconciliation

```json
{
  "format": "jsonl",
  "text": "{\"n\":1}\nbad\n{\"n\":2}"
}
```

Expected result fields:

```json
{
  "input_records": 3,
  "accepted_before_operations": 2
}
```

## duplicate header

```json
{
  "format": "csv",
  "text": "n,n\n1,2"
}
```

Expected: nonzero exit with an input error.

## unclosed quote

```json
{
  "format": "csv",
  "text": "n\n\"x"
}
```

Expected: nonzero exit with an input error.

## join duplicates forbidden

```json
{
  "rows": [
    {
      "id": 1
    }
  ],
  "join": {
    "rows": [
      {
        "id": 1
      },
      {
        "id": 1
      }
    ],
    "left_key": "id",
    "right_key": "id"
  }
}
```

Expected: nonzero exit with an input error.
