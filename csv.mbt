///|
pub fn read_csv(
  source : String,
  delimiter? : Char = ',',
) -> Array[Array[String]] raise InputError {
  let rows : Array[Array[String]] = []
  let mut row : Array[String] = []
  let mut field = ""
  let mut quoted = false
  let mut closed = false
  let mut pending_cr = false
  for c in source {
    if pending_cr && c == '\n' {
      pending_cr = false
      continue
    }
    pending_cr = false
    if quoted {
      if c == '"' {
        quoted = false
        closed = true
      } else {
        field += c.to_string()
      }
    } else if closed && c == '"' {
      field += "\""
      quoted = true
      closed = false
    } else if c == delimiter {
      row.push(field)
      field = ""
      closed = false
    } else if c == '\n' || c == '\r' {
      row.push(field)
      rows.push(row)
      row = []
      field = ""
      closed = false
      pending_cr = c == '\r'
    } else if c == '"' {
      if field != "" {
        raise InputError("quote in unquoted CSV field")
      }
      quoted = true
    } else {
      if closed {
        raise InputError("characters after closing CSV quote")
      }
      field += c.to_string()
    }
  }
  if quoted {
    raise InputError("unterminated CSV field")
  }
  if field != "" || !row.is_empty() || closed {
    row.push(field)
    rows.push(row)
  }
  rows
}

///|
pub fn write_csv(
  rows : Array[Array[String]],
  delimiter? : String = ",",
) -> String {
  rows
  .map(fn(row) {
    row
    .map(fn(cell) {
      if cell.contains(delimiter) ||
        cell.contains("\"") ||
        cell.contains("\n") ||
        cell.contains("\r") {
        "\"" + cell.replace_all(old="\"", new="\"\"") + "\""
      } else {
        cell
      }
    })
    .join(delimiter)
  })
  .join("\r\n")
}

///|
fn csv_records(source : String) -> Array[Value] raise InputError {
  let matrix = read_csv(source)
  if matrix.is_empty() {
    return []
  }
  let headers = matrix[0]
  let seen : Map[String, Bool] = {}
  for header in headers {
    if header == "" || seen.contains(header) {
      raise InputError("empty or duplicate CSV header")
    }
    seen[header] = true
  }
  let records : Array[Value] = []
  for i = 1; i < matrix.length(); i = i + 1 {
    let row = matrix[i]
    if row.length() != headers.length() {
      raise InputError("CSV width mismatch at row " + (i + 1).to_string())
    }
    let values : Map[String, Value] = {}
    for j = 0; j < headers.length(); j = j + 1 {
      values[headers[j]] = String(row[j])
    }
    records.push(Object(values))
  }
  records
}
