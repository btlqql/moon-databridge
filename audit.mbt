///|
pub fn quality_gate(config : Value, input : Int, rejected : Int) -> Value raise {
  if input < 0 || rejected < 0 || rejected > input {
    raise InputError("invalid quality gate row counts")
  }
  let fraction = if input == 0 {
    0.0
  } else {
    rejected.to_double() / input.to_double()
  }
  let violations : Array[String] = []
  if config != Null {
    for key, _ in obj(config) {
      if !["max_rejected", "max_rejection_fraction"].contains(key) {
        raise InputError("unknown quality gate option: " + key)
      }
    }
    if get(config, "max_rejected") != Null {
      let limit = num(get(config, "max_rejected"))
      if limit < 0.0 || limit.floor() != limit {
        raise InputError("max_rejected must be a nonnegative integer")
      }
      if rejected.to_double() > limit {
        violations.push("max_rejected")
      }
    }
    if get(config, "max_rejection_fraction") != Null {
      let limit = num(get(config, "max_rejection_fraction"))
      if limit < 0.0 || limit > 1.0 {
        raise InputError("max_rejection_fraction must be between zero and one")
      }
      if fraction > limit {
        violations.push("max_rejection_fraction")
      }
    }
  }
  record([
    ("passed", Bool(violations.is_empty())),
    ("rejected", Number(rejected.to_double())),
    ("rejection_fraction", Number(fraction)),
    ("violations", strings(violations)),
  ])
}

///|
fn audit_rows(
  input : Int,
  rejected : Int,
  accepted : Int,
  filtered : Int,
  deduplicated : Int,
  join_discarded : Int,
  before_group : Int,
  returned : Int,
) -> Value raise {
  let conserved = input ==
    rejected + filtered + deduplicated + join_discarded + before_group &&
    input == accepted + rejected
  if !conserved {
    raise InputError("internal row reconciliation failed")
  }
  record([
    ("input", Number(input.to_double())),
    ("rejected", Number(rejected.to_double())),
    ("accepted", Number(accepted.to_double())),
    ("filtered", Number(filtered.to_double())),
    ("deduplicated", Number(deduplicated.to_double())),
    ("join_discarded", Number(join_discarded.to_double())),
    ("before_group", Number(before_group.to_double())),
    ("returned", Number(returned.to_double())),
    ("conserved", Bool(conserved)),
  ])
}
