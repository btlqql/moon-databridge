///|
fn test_at(value : Value, parts : Array[String]) -> Value raise {
  let mut current = value
  for part in parts {
    current = match current {
      Object(fields) =>
        match fields.get(part) {
          Some(v) => v
          None => raise InputError("test key missing: " + part)
        }
      Array(items) => items[num(parse_value(part)).to_int()]
      _ => raise InputError("invalid test traversal")
    }
  }
  current
}

///|
test "quoted multiline CSV" {
  let result = run(
    parse_value(
      "{\"format\":\"csv\",\"text\":\"id,note\\r\\n1,\\\"a,b\\\"\\r\\n2,\\\"line1\\nline2\\\"\\r\\n\"}",
    ),
  )
  assert_eq(test_at(result, ["rows", "0", "note"]), parse_value("\"a,b\""))
  assert_eq(
    test_at(result, ["rows", "1", "note"]),
    parse_value("\"line1\\nline2\""),
  )
  assert_eq(test_at(result, ["input_records"]), parse_value("2"))
}

///|
test "typed quarantine" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"n\":\"7\"},{\"n\":\"bad\"},{}],\"columns\":[{\"source\":\"n\",\"type\":\"integer\",\"required\":true}]}",
    ),
  )
  assert_eq(test_at(result, ["rows", "0", "n"]), parse_value("7"))
  assert_eq(test_at(result, ["accepted_before_operations"]), parse_value("1"))
  assert_eq(test_at(result, ["input_records"]), parse_value("3"))
}

///|
test "join filter deduplicate" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"id\":1,\"n\":3},{\"id\":1,\"n\":3},{\"id\":2,\"n\":0}],\"filter\":{\"field\":\"n\",\"op\":\"gt\",\"value\":1},\"deduplicate\":[\"id\"],\"join\":{\"rows\":[{\"key\":1,\"name\":\"alpha\"}],\"left_key\":\"id\",\"right_key\":\"key\"}}",
    ),
  )
  assert_eq(test_at(result, ["deduplicated"]), parse_value("1"))
  assert_eq(
    test_at(result, ["rows", "0", "right_name"]),
    parse_value("\"alpha\""),
  )
}

///|
test "group sum mean" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"g\":\"a\",\"n\":2},{\"g\":\"a\",\"n\":4}],\"group\":{\"keys\":[\"g\"],\"value\":\"n\"}}",
    ),
  )
  assert_eq(test_at(result, ["rows", "0", "sum"]), parse_value("6"))
  assert_eq(test_at(result, ["rows", "0", "mean"]), parse_value("3"))
  assert_eq(test_at(result, ["rows", "0", "count"]), parse_value("2"))
}

///|
test "JSONL reconciliation" {
  let result = run(
    parse_value(
      "{\"format\":\"jsonl\",\"text\":\"{\\\"n\\\":1}\\nbad\\n{\\\"n\\\":2}\"}",
    ),
  )
  assert_eq(test_at(result, ["input_records"]), parse_value("3"))
  assert_eq(test_at(result, ["accepted_before_operations"]), parse_value("2"))
}

///|
test "duplicate header" {
  let failed = try {
    ignore(run(parse_value("{\"format\":\"csv\",\"text\":\"n,n\\n1,2\"}")))
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}

///|
test "unclosed quote" {
  let failed = try {
    ignore(run(parse_value("{\"format\":\"csv\",\"text\":\"n\\n\\\"x\"}")))
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}

///|
test "join duplicates forbidden" {
  let failed = try {
    ignore(
      run(
        parse_value(
          "{\"rows\":[{\"id\":1}],\"join\":{\"rows\":[{\"id\":1},{\"id\":1}],\"left_key\":\"id\",\"right_key\":\"id\"}}",
        ),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}
