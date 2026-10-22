///|
test "review lexical sort" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"s\":\"b\"},{\"s\":\"aa\"},{\"s\":\"a\"}],\"sort\":\"s\"}",
    ),
  )
  assert_eq(
    test_at(result, ["rows"]),
    parse_value("[{\"s\":\"a\"},{\"s\":\"aa\"},{\"s\":\"b\"}]"),
  )
}

///|
test "review lexical filter" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"s\":\"b\"},{\"s\":\"aa\"}],\"filter\":{\"field\":\"s\",\"op\":\"gt\",\"value\":\"aa\"}}",
    ),
  )
  assert_eq(test_at(result, ["rows"]), parse_value("[{\"s\":\"b\"}]"))
}

///|
test "review integer scale preserves type" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"n\":3},{\"n\":4}],\"columns\":[{\"source\":\"n\",\"type\":\"integer\",\"scale\":0.5}],\"quality_gate\":{\"max_rejected\":0}}",
    ),
  )
  assert_eq(test_at(result, ["rows"]), parse_value("[{\"n\":2}]"))
  assert_eq(test_at(result, ["audit", "rejected"]), parse_value("1"))
  assert_eq(test_at(result, ["audit", "conserved"]), parse_value("true"))
  assert_eq(test_at(result, ["quality_gate", "passed"]), parse_value("false"))
}

///|
test "review unknown request" {
  let mut rejected = false
  ignore(run(parse_value("{\"rows\":[],\"typo\":true}"))) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review unknown column" {
  let mut rejected = false
  ignore(
    run(
      parse_value(
        "{\"rows\":[],\"columns\":[{\"source\":\"n\",\"required_typo\":true}]}",
      ),
    ),
  ) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review unknown leaf condition" {
  let mut rejected = false
  ignore(
    run(
      parse_value(
        "{\"rows\":[],\"filter\":{\"field\":\"n\",\"operator_typo\":\"gt\"}}",
      ),
    ),
  ) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review invalid empty join flag" {
  let mut rejected = false
  ignore(
    run(
      parse_value(
        "{\"rows\":[],\"join\":{\"rows\":[],\"left_key\":\"id\",\"right_key\":\"id\",\"inner\":\"false\"}}",
      ),
    ),
  ) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review empty join key" {
  let mut rejected = false
  ignore(
    run(
      parse_value(
        "{\"rows\":[],\"join\":{\"rows\":[],\"left_key\":\"\",\"right_key\":\"id\"}}",
      ),
    ),
  ) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review empty group value" {
  let mut rejected = false
  ignore(
    run(parse_value("{\"rows\":[],\"group\":{\"keys\":[],\"value\":\"\"}}")),
  ) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review duplicate group key" {
  let mut rejected = false
  ignore(
    run(
      parse_value(
        "{\"rows\":[],\"group\":{\"keys\":[\"id\",\"id\"],\"value\":\"n\"}}",
      ),
    ),
  ) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review duplicate export key" {
  let mut rejected = false
  ignore(run(parse_value("{\"rows\":[],\"export_columns\":[\"id\",\"id\"]}"))) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review empty export key" {
  let mut rejected = false
  ignore(run(parse_value("{\"rows\":[],\"export_columns\":[]}"))) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review duplicate dedup key" {
  let mut rejected = false
  ignore(run(parse_value("{\"rows\":[],\"deduplicate\":[\"id\",\"id\"]}"))) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}

///|
test "review unknown join property" {
  let mut rejected = false
  ignore(
    run(
      parse_value(
        "{\"rows\":[],\"join\":{\"rows\":[],\"left_key\":\"id\",\"right_key\":\"id\",\"innre\":true}}",
      ),
    ),
  ) catch {
    _ => rejected = true
  }
  assert_true(rejected)
}
