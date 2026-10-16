///|
test "invalid schema is rejected even with no data rows" {
  for
    source in [
      "{\"rows\":[],\"columns\":[{\"source\":\"x\",\"type\":\"bogus\"}]}", "{\"rows\":[],\"columns\":[{\"source\":\"x\",\"required\":\"false\"}]}",
      "{\"rows\":[],\"columns\":[{\"source\":\"x\",\"min\":3,\"max\":1}]}", "{\"rows\":[],\"columns\":[{\"source\":\"x\"},{\"source\":\"x\"}]}",
    ] {
    let failed = try {
      ignore(run(parse_value(source)))
      false
    } catch {
      _ => true
    }
    assert_true(failed)
  }
}

///|
test "aggregation cannot overwrite a grouping dimension" {
  let failed = try {
    ignore(
      group_rows(
        [record([("count", String("a")), ("n", Number(1.0))])],
        ["count"],
        "n",
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
  let global = group_rows(
    [record([("n", Number(2.0))]), record([("n", Number(4.0))])],
    [],
    "n",
  )
  assert_eq(get(global[0], "sum"), Number(6.0))
}
