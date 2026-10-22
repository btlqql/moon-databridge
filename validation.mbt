///|
fn validate_columns(columns : Value) -> Unit raise {
  if columns == Null {
    return
  }
  let targets : Map[String, Bool] = Map([])
  for column in arr(columns) {
    fields_only(column, [
      "source", "target", "type", "default", "required", "trim", "lower", "empty_as_null",
      "min", "max", "enum", "scale",
    ])
    ignore(obj(column))
    let source = str(get(column, "source"))
    let target = optional_str(get(column, "target"), source)
    if source == "" || target == "" || targets.contains(target) {
      raise InputError("empty source/target or duplicate target column")
    }
    targets[target] = true
    let kind = optional_str(get(column, "type"), "any")
    if !["any", "string", "number", "integer", "boolean"].contains(kind) {
      raise InputError("unknown column type: " + kind)
    }
    for flag in ["required", "trim", "lower", "empty_as_null"] {
      match get(column, flag) {
        Null | Bool(_) => ()
        _ => raise InputError("column flag must be boolean: " + flag)
      }
    }
    for key in ["min", "max", "scale"] {
      if get(column, key) != Null {
        ignore(num(get(column, key)))
      }
    }
    if get(column, "min") != Null &&
      get(column, "max") != Null &&
      num(get(column, "min")) > num(get(column, "max")) {
      raise InputError("column minimum exceeds maximum")
    }
    if get(column, "enum") != Null {
      ignore(arr(get(column, "enum")))
    }
  }
}

///|
fn validate_group_keys(keys : Array[String]) -> Unit raise InputError {
  let seen : Map[String, Bool] = Map([])
  for key in keys {
    if key == "" || ["count", "sum", "mean"].contains(key) || seen.contains(key) {
      raise InputError("duplicate, empty or aggregate-reserved group key")
    }
    seen[key] = true
  }
}
