///|
pub fn run(request : Value) -> Value raise {
  let columns = get(request, "columns")
  validate_columns(columns)
  ignore(quality_gate(get(request, "quality_gate"), 0, 0))
  let rejected : Array[Value] = []
  let format = optional_str(get(request, "format"), "rows")
  let source : Array[Value] = match format {
    "rows" => arr(get(request, "rows"))
    "csv" => csv_records(str(get(request, "text")))
    "jsonl" => {
      let result : Array[Value] = []
      let mut line_number = 0
      for line in str(get(request, "text")).split("\n") {
        line_number += 1
        if line.trim().is_empty() {
          continue
        }
        result.push(parse_value(line)) catch {
          error =>
            rejected.push(
              record([
                ("line", Number(line_number.to_double())),
                ("reason", String(error.to_string())),
              ]),
            )
        }
      }
      result
    }
    _ => raise InputError("format must be rows, csv or jsonl")
  }
  let input_records = source.length() + rejected.length()
  let mut output : Array[Value] = []
  for i = 0; i < source.length(); i = i + 1 {
    try {
      ignore(obj(source[i]))
      output.push(
        if columns == Null {
          source[i]
        } else {
          transform_row(source[i], arr(columns))
        },
      )
    } catch {
      error =>
        rejected.push(
          record([
            ("row", Number(i.to_double())),
            ("input", source[i]),
            ("reason", String(error.to_string())),
          ]),
        )
    }
  }
  let accepted = output.length()
  if get(request, "filter") != Null {
    output = filter_rows(output, get(request, "filter"))
  }
  let before_dedup = output.length()
  let filtered = accepted - before_dedup
  if get(request, "deduplicate") != Null {
    let keys = string_list(get(request, "deduplicate"))
    if keys.is_empty() {
      raise InputError("deduplicate needs at least one key")
    }
    let seen : Map[String, Bool] = {}
    output = output.filter(fn(row) {
      let key = row_key(row, keys)
      if seen.contains(key) {
        false
      } else {
        seen[key] = true
        true
      }
    })
  }
  let deduplicated = before_dedup - output.length()
  let before_join = output.length()
  if get(request, "join") != Null {
    let join = get(request, "join")
    output = join_rows(
      output,
      arr(get(join, "rows")),
      str(get(join, "left_key")),
      str(get(join, "right_key")),
      prefix=optional_str(get(join, "prefix"), "right_"),
      inner=truth(get(join, "inner")),
    )
  }
  if get(request, "sort") != Null {
    let key = str(get(request, "sort"))
    output.sort_by(fn(a, b) { compare_value(get(a, key), get(b, key)) })
  }
  let before_group = output.length()
  let join_discarded = before_join - before_group
  let profile = profile_rows(output)
  if get(request, "group") != Null {
    let group = get(request, "group")
    output = group_rows(
      output,
      string_list(get(group, "keys")),
      str(get(group, "value")),
    )
  }
  let csv = if get(request, "export_columns") == Null {
    Null
  } else {
    let keys = string_list(get(request, "export_columns"))
    let matrix = [keys]
    for row in output {
      matrix.push(
        keys.map(fn(k) {
          match get(row, k) {
            String(s) => s
            Null => ""
            value => canonical(value)
          }
        }),
      )
    }
    String(write_csv(matrix))
  }
  record([
    ("rows", Array(output)),
    ("rejected", Array(rejected)),
    ("profile", profile),
    ("csv", csv),
    ("accepted_before_operations", Number(accepted.to_double())),
    ("deduplicated", Number(deduplicated.to_double())),
    ("input_records", Number(input_records.to_double())),
    (
      "audit",
      audit_rows(
        input_records,
        rejected.length(),
        accepted,
        filtered,
        deduplicated,
        join_discarded,
        before_group,
        output.length(),
      ),
    ),
    (
      "quality_gate",
      quality_gate(
        get(request, "quality_gate"),
        input_records,
        rejected.length(),
      ),
    ),
  ])
}
