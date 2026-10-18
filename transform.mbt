///|
fn convert(value : Value, kind : String) -> Value raise InputError {
  if value == Null {
    return Null
  }
  match kind {
    "any" => value
    "string" =>
      match value {
        String(_) => value
        _ => String(canonical(value))
      }
    "number" | "integer" => {
      let number = match value {
        Number(n) => n
        String(s) =>
          num(parse_value(s.trim().to_string())) catch {
            _ => raise InputError("invalid numeric text")
          }
        _ => raise InputError("cannot convert to number")
      }
      if number.is_nan() ||
        number.is_inf() ||
        (kind == "integer" && number.floor() != number) {
        raise InputError("invalid number")
      }
      Number(number)
    }
    "boolean" =>
      match value {
        Bool(_) => value
        String("true") => Bool(true)
        String("false") => Bool(false)
        _ => raise InputError("cannot convert to boolean")
      }
    _ => raise InputError("unknown column type: " + kind)
  }
}

///|
fn transform_row(row : Value, columns : Array[Value]) -> Value raise InputError {
  let result : Map[String, Value] = {}
  let source = obj(row)
  for column in columns {
    let from = str(get(column, "source"))
    let to = optional_str(get(column, "target"), from)
    if result.contains(to) {
      raise InputError("duplicate target column: " + to)
    }
    let mut value = source.get(from).unwrap_or(get(column, "default"))
    if value == Null && truth(get(column, "required")) {
      raise InputError("required column: " + from)
    }
    if value is String(s) {
      let mut text = if truth(get(column, "trim")) {
        s.trim().to_string()
      } else {
        s
      }
      if truth(get(column, "lower")) {
        text = text.to_lower()
      }
      if text == "" && truth(get(column, "empty_as_null")) {
        value = Null
      } else {
        value = String(text)
      }
    }
    value = convert(value, optional_str(get(column, "type"), "any"))
    if value == Null && truth(get(column, "required")) {
      raise InputError("required column: " + from)
    }
    if value != Null {
      if get(column, "min") != Null && num(value) < num(get(column, "min")) {
        raise InputError("below minimum: " + from)
      }
      if get(column, "max") != Null && num(value) > num(get(column, "max")) {
        raise InputError("above maximum: " + from)
      }
      if get(column, "enum") != Null &&
        !arr(get(column, "enum")).contains(value) {
        raise InputError("not in enum: " + from)
      }
      if get(column, "scale") != Null {
        let scaled = num(value) * num(get(column, "scale"))
        if scaled.is_inf() || scaled.is_nan() {
          raise InputError("scaled number overflow: " + from)
        }
        value = Number(scaled)
      }
    }
    result[to] = value
  }
  Object(result)
}

///|
fn compare_value(a : Value, b : Value) -> Int {
  match (a, b) {
    (Number(x), Number(y)) => x.compare(y)
    (String(x), String(y)) => x.compare(y)
    _ => canonical(a).compare(canonical(b))
  }
}

///|
fn match_leaf(row : Value, condition : Value) -> Bool raise InputError {
  let actual = get(row, str(get(condition, "field")))
  let expected = get(condition, "value")
  match optional_str(get(condition, "op"), "eq") {
    "eq" => actual == expected
    "ne" => actual != expected
    "gt" => compare_value(actual, expected) > 0
    "ge" => compare_value(actual, expected) >= 0
    "lt" => compare_value(actual, expected) < 0
    "le" => compare_value(actual, expected) <= 0
    "in" => arr(expected).contains(actual)
    "contains" => str(actual).contains(str(expected))
    "exists" => actual != Null
    _ => raise InputError("unknown filter operation")
  }
}

///|
fn row_key(row : Value, keys : Array[String]) -> String {
  canonical(Array(keys.map(fn(key) { get(row, key) })))
}

///|
pub fn join_rows(
  left : Array[Value],
  right : Array[Value],
  left_key : String,
  right_key : String,
  prefix? : String = "right_",
  inner? : Bool = false,
) -> Array[Value] raise InputError {
  let index : Map[String, Value] = {}
  for row in right {
    let value = get(row, right_key)
    if value == Null {
      raise InputError("null right join key")
    }
    let key = canonical(value)
    if index.contains(key) {
      raise InputError("duplicate right join key")
    }
    index[key] = row
  }
  let output : Array[Value] = []
  for row in left {
    let key = get(row, left_key)
    let matched = if key == Null { None } else { index.get(canonical(key)) }
    if inner && matched is None {
      continue
    }
    let fields = obj(row).copy()
    match matched {
      Some(other) =>
        for key, value in obj(other) {
          let target = prefix + key
          if fields.contains(target) {
            raise InputError("join column collision: " + target)
          }
          fields[target] = value
        }
      None => ()
    }
    output.push(Object(fields))
  }
  output
}

///|
pub fn profile_rows(rows : Array[Value]) -> Value raise InputError {
  let names : Map[String, Bool] = {}
  for row in rows {
    for name, _ in obj(row) {
      names[name] = true
    }
  }
  let profile : Map[String, Value] = {}
  for name, _ in names {
    let distinct : Map[String, Bool] = {}
    let kinds : Map[String, Bool] = {}
    let mut missing = 0
    let mut total = 0.0
    let mut numeric_count = 0
    let mut min = 1.7976931348623157e308
    let mut max = -1.7976931348623157e308
    for row in rows {
      let value = get(row, name)
      distinct[canonical(value)] = true
      match value {
        Null => {
          missing = missing + 1
          kinds["null"] = true
        }
        Number(n) => {
          kinds["number"] = true
          total += n
          numeric_count += 1
          min = min.min(n)
          max = max.max(n)
        }
        String(_) => kinds["string"] = true
        Bool(_) => kinds["boolean"] = true
        Array(_) => kinds["array"] = true
        Object(_) => kinds["object"] = true
      }
    }
    if total.is_inf() || total.is_nan() {
      raise InputError("profile sum overflow")
    }
    let type_names = kinds.keys().collect()
    type_names.sort()
    profile[name] = record([
      ("types", strings(type_names)),
      ("missing", Number(missing.to_double())),
      ("distinct", Number(distinct.length().to_double())),
      ("sum", Number(total)),
      ("min", if numeric_count == 0 { Null } else { Number(min) }),
      ("max", if numeric_count == 0 { Null } else { Number(max) }),
    ])
  }
  Object(profile)
}

///|
pub fn group_rows(
  rows : Array[Value],
  keys : Array[String],
  value_field : String,
) -> Array[Value] raise InputError {
  validate_group_keys(keys)
  let groups : Map[String, Array[Value]] = {}
  for row in rows {
    let key = row_key(row, keys)
    let bucket = groups.get(key).unwrap_or([])
    bucket.push(row)
    groups[key] = bucket
  }
  let ordered = groups.keys().collect()
  ordered.sort()
  ordered.map(fn(key) {
    let bucket = groups[key]
    let mut total = 0.0
    for row in bucket {
      total += num(get(row, value_field))
    }
    if total.is_inf() || total.is_nan() {
      raise InputError("group sum overflow")
    }
    let values = keys.map(fn(k) { (k, get(bucket[0], k)) })
    values.push(("count", Number(bucket.length().to_double())))
    values.push(("sum", Number(total)))
    values.push(("mean", Number(total / bucket.length().to_double())))
    record(values)
  })
}
