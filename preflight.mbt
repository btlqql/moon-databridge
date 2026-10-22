///|
fn fields_only(value : Value, allowed : Array[String]) -> Unit raise InputError {
  for name, _ in obj(value) {
    if !allowed.contains(name) {
      raise InputError("unknown option: " + name)
    }
  }
}

///|
fn named_field(value : Value) -> String raise InputError {
  let name = str(value)
  if name == "" {
    raise InputError("field name must not be empty")
  }
  name
}

///|
fn distinct_fields(
  value : Value,
  nonempty : Bool,
) -> Array[String] raise InputError {
  let names = string_list(value)
  if nonempty && names.is_empty() {
    raise InputError("at least one field is required")
  }
  let seen : Map[String, Bool] = Map([])
  for name in names {
    ignore(named_field(String(name)))
    if seen.contains(name) {
      raise InputError("duplicate field: " + name)
    }
    seen[name] = true
  }
  names
}

///|
fn validate_pipeline(request : Value) -> Unit raise {
  fields_only(request, [
    "format", "rows", "text", "columns", "filter", "deduplicate", "join", "sort",
    "group", "export_columns", "quality_gate",
  ])
  if get(request, "filter") != Null {
    validate_condition(get(request, "filter"), 0)
  }
  if get(request, "deduplicate") != Null {
    ignore(distinct_fields(get(request, "deduplicate"), true))
  }
  if get(request, "export_columns") != Null {
    ignore(distinct_fields(get(request, "export_columns"), true))
  }
  if get(request, "sort") != Null {
    ignore(named_field(get(request, "sort")))
  }
  if get(request, "join") != Null {
    let join = get(request, "join")
    fields_only(join, ["rows", "left_key", "right_key", "prefix", "inner"])
    ignore(arr(get(join, "rows")))
    ignore(named_field(get(join, "left_key")))
    ignore(named_field(get(join, "right_key")))
    ignore(optional_str(get(join, "prefix"), "right_"))
    match get(join, "inner") {
      Null | Bool(_) => ()
      _ => raise InputError("join inner must be boolean")
    }
  }
  if get(request, "group") != Null {
    let group = get(request, "group")
    fields_only(group, ["keys", "value"])
    validate_group_keys(distinct_fields(get(group, "keys"), false))
    ignore(named_field(get(group, "value")))
  }
}

///|
fn lexical_compare(left : String, right : String) -> Int32 {
  let a = left.to_array()
  let b = right.to_array()
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    let order = a[i].compare(b[i])
    if order != 0 {
      return order
    }
  }
  a.length().compare(b.length())
}
