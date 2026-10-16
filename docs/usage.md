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


# 0.2.0 additional executable scenarios

## reconcile every pipeline stage

```json
{
  "rows": [
    {
      "id": "a",
      "n": "2"
    },
    {
      "id": "a",
      "n": "2"
    },
    {
      "id": "b",
      "n": "0"
    },
    {
      "id": "c",
      "n": "bad"
    },
    {
      "id": "d",
      "n": "4"
    }
  ],
  "columns": [
    {
      "source": "id",
      "type": "string"
    },
    {
      "source": "n",
      "type": "number",
      "required": true
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
        "id": "a",
        "category": "x"
      }
    ],
    "left_key": "id",
    "right_key": "id",
    "inner": true
  },
  "group": {
    "keys": [],
    "value": "n"
  },
  "quality_gate": {
    "max_rejected": 0,
    "max_rejection_fraction": 0.1
  }
}
```

Expected result fields:

```json
{
  "audit": {
    "input": 5,
    "rejected": 1,
    "accepted": 4,
    "filtered": 1,
    "deduplicated": 1,
    "join_discarded": 1,
    "before_group": 1,
    "returned": 1,
    "conserved": true
  },
  "quality_gate/passed": false,
  "quality_gate/violations": [
    "max_rejected",
    "max_rejection_fraction"
  ],
  "rows/0/sum": 2
}
```

## quality threshold equality

```json
{
  "format": "jsonl",
  "text": "{\"n\":1}\nbad\n{\"n\":2}",
  "quality_gate": {
    "max_rejected": 1,
    "max_rejection_fraction": 0.5
  }
}
```

Expected result fields:

```json
{
  "audit/input": 3,
  "audit/rejected": 1,
  "quality_gate/passed": true
}
```

## empty quality denominator

```json
{
  "rows": [],
  "quality_gate": {
    "max_rejected": 0,
    "max_rejection_fraction": 0
  }
}
```

Expected result fields:

```json
{
  "quality_gate/passed": true,
  "quality_gate/rejection_fraction": 0,
  "audit/conserved": true
}
```

## all rejected remains conserved

```json
{
  "rows": [
    {
      "n": "bad"
    }
  ],
  "columns": [
    {
      "source": "n",
      "type": "number"
    }
  ],
  "quality_gate": {
    "max_rejection_fraction": 0.5
  }
}
```

Expected result fields:

```json
{
  "rows": [],
  "audit/conserved": true,
  "quality_gate/passed": false,
  "quality_gate/rejection_fraction": 1
}
```

## bad quality limit

```json
{
  "rows": [],
  "quality_gate": {
    "max_rejected": 1.5
  }
}
```

Expected: an input error.

## unknown quality option

```json
{
  "rows": [],
  "quality_gate": {
    "max_errors": 0
  }
}
```

Expected: an input error.
