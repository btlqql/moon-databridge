///|
test "reconcile every pipeline stage" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"id\":\"a\",\"n\":\"2\"},{\"id\":\"a\",\"n\":\"2\"},{\"id\":\"b\",\"n\":\"0\"},{\"id\":\"c\",\"n\":\"bad\"},{\"id\":\"d\",\"n\":\"4\"}],\"columns\":[{\"source\":\"id\",\"type\":\"string\"},{\"source\":\"n\",\"type\":\"number\",\"required\":true}],\"filter\":{\"field\":\"n\",\"op\":\"gt\",\"value\":1},\"deduplicate\":[\"id\"],\"join\":{\"rows\":[{\"id\":\"a\",\"category\":\"x\"}],\"left_key\":\"id\",\"right_key\":\"id\",\"inner\":true},\"group\":{\"keys\":[],\"value\":\"n\"},\"quality_gate\":{\"max_rejected\":0,\"max_rejection_fraction\":0.1}}",
    ),
  )
  assert_eq(
    test_at(result, ["audit"]),
    parse_value(
      "{\"input\":5,\"rejected\":1,\"accepted\":4,\"filtered\":1,\"deduplicated\":1,\"join_discarded\":1,\"before_group\":1,\"returned\":1,\"conserved\":true}",
    ),
  )
  assert_eq(test_at(result, ["quality_gate", "passed"]), parse_value("false"))
  assert_eq(
    test_at(result, ["quality_gate", "violations"]),
    parse_value("[\"max_rejected\",\"max_rejection_fraction\"]"),
  )
  assert_eq(test_at(result, ["rows", "0", "sum"]), parse_value("2"))
}

///|
test "quality threshold equality" {
  let result = run(
    parse_value(
      "{\"format\":\"jsonl\",\"text\":\"{\\\"n\\\":1}\\nbad\\n{\\\"n\\\":2}\",\"quality_gate\":{\"max_rejected\":1,\"max_rejection_fraction\":0.5}}",
    ),
  )
  assert_eq(test_at(result, ["audit", "input"]), parse_value("3"))
  assert_eq(test_at(result, ["audit", "rejected"]), parse_value("1"))
  assert_eq(test_at(result, ["quality_gate", "passed"]), parse_value("true"))
}

///|
test "empty quality denominator" {
  let result = run(
    parse_value(
      "{\"rows\":[],\"quality_gate\":{\"max_rejected\":0,\"max_rejection_fraction\":0}}",
    ),
  )
  assert_eq(test_at(result, ["quality_gate", "passed"]), parse_value("true"))
  assert_eq(
    test_at(result, ["quality_gate", "rejection_fraction"]),
    parse_value("0"),
  )
  assert_eq(test_at(result, ["audit", "conserved"]), parse_value("true"))
}

///|
test "all rejected remains conserved" {
  let result = run(
    parse_value(
      "{\"rows\":[{\"n\":\"bad\"}],\"columns\":[{\"source\":\"n\",\"type\":\"number\"}],\"quality_gate\":{\"max_rejection_fraction\":0.5}}",
    ),
  )
  assert_eq(test_at(result, ["rows"]), parse_value("[]"))
  assert_eq(test_at(result, ["audit", "conserved"]), parse_value("true"))
  assert_eq(test_at(result, ["quality_gate", "passed"]), parse_value("false"))
  assert_eq(
    test_at(result, ["quality_gate", "rejection_fraction"]),
    parse_value("1"),
  )
}

///|
test "bad quality limit" {
  let failed = try {
    ignore(
      run(parse_value("{\"rows\":[],\"quality_gate\":{\"max_rejected\":1.5}}")),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}

///|
test "unknown quality option" {
  let failed = try {
    ignore(
      run(parse_value("{\"rows\":[],\"quality_gate\":{\"max_errors\":0}}")),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}
