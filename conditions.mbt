///|
fn validate_condition(condition : Value, depth : Int) -> Unit raise {
  if depth > 64 { raise InputError("filter nesting limit") }
  let fields=obj(condition)
  let composites=["all","any","not"].filter(fn(key){fields.contains(key)})
  if !composites.is_empty() {
    if composites.length()!=1 || fields.size()!=1 { raise InputError("composite filter must contain exactly one operator") }
    let op=composites[0]
    if op=="not" { validate_condition(fields[op],depth+1) } else { for child in arr(fields[op]) { validate_condition(child,depth+1) } }
  } else {
    if str(get(condition,"field"))=="" { raise InputError("filter field cannot be empty") }
    let op=optional_str(get(condition,"op"),"eq")
    if !["eq","ne","gt","ge","lt","le","in","contains","exists"].contains(op) { raise InputError("unknown filter operator") }
    if op=="in" { ignore(arr(get(condition,"value"))) }
    if op=="contains" { ignore(str(get(condition,"value"))) }
  }
}

///|
fn condition_match(row : Value, condition : Value, depth : Int) -> Bool raise {
  if depth>64 { raise InputError("filter nesting limit") }
  let fields=obj(condition)
  if fields.contains("all") { return arr(fields["all"]).all(fn(child){condition_match(row,child,depth+1)}) }
  if fields.contains("any") { return arr(fields["any"]).any(fn(child){condition_match(row,child,depth+1)}) }
  if fields.contains("not") { return !condition_match(row,fields["not"],depth+1) }
  match_leaf(row,condition)
}

///|
pub fn filter_rows(rows : Array[Value], condition : Value) -> Array[Value] raise {
  validate_condition(condition,0)
  rows.filter(fn(row){condition_match(row,condition,0)})
}
