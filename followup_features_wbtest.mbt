///|
fn followup_at(value : Value, keys : Array[String]) -> Value raise {
  let mut current=value
  for key in keys { current=match current { Object(fields)=>fields[key]; Array(items)=> { let index=match @json.parse(key) { Json::Number(n, ..)=>n.to_int(); _=>raise InputError("invalid test index") }; items[index] }; _=>raise InputError("invalid test path") } }
  current
}

///|
test "followup composite eligibility" {
  let result=run(from_json(@json.parse("{\"rows\":[{\"n\":1,\"kind\":\"a\"},{\"n\":2,\"kind\":\"b\"},{\"n\":3,\"kind\":\"a\"}],\"filter\":{\"all\":[{\"field\":\"n\",\"op\":\"ge\",\"value\":2},{\"not\":{\"field\":\"kind\",\"value\":\"b\"}}]}}")))
  assert_eq(followup_at(result,["rows"]),from_json(@json.parse("[{\"n\":3,\"kind\":\"a\"}]")))
  assert_eq(followup_at(result,["audit","filtered"]),from_json(@json.parse("2")))
}

///|
test "followup empty logical identities" {
  let result=run(from_json(@json.parse("{\"rows\":[{\"n\":1}],\"filter\":{\"any\":[]}}")))
  assert_eq(followup_at(result,["rows"]),from_json(@json.parse("[]")))
  assert_eq(followup_at(result,["audit","conserved"]),from_json(@json.parse("true")))
}

///|
test "followup invalid empty batch filter" {
  let bad=try { ignore(run(from_json(@json.parse("{\"rows\":[],\"filter\":{\"all\":[],\"field\":\"x\"}}")))); false } catch { _=>true }; assert_true(bad)
}

///|
test "followup or branches" {
  let result=run(from_json(@json.parse("{\"rows\":[{\"n\":1},{\"n\":2},{\"n\":3}],\"filter\":{\"any\":[{\"field\":\"n\",\"value\":1},{\"field\":\"n\",\"value\":3}]}}")))
  assert_eq(followup_at(result,["rows"]),from_json(@json.parse("[{\"n\":1},{\"n\":3}]")))
}
