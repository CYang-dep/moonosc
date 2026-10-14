///|
fn spend(work : Ref[Int], limit : Int) -> Unit raise OscError {
  if work.val >= limit {
    raise Limit("pattern work budget")
  }
  work.val += 1
}

///|
/// Dynamic programming, no recursive backtracking; wildcard never crosses '/'.
pub fn Pattern::matches(
  self : Pattern,
  method : String,
  work_limit? : Int = 1000000,
) -> Bool raise OscError {
  validate_method(method)
  if method.length() > 4096 {
    raise Limit("method length")
  }
  if work_limit < 1 || work_limit > 16777216 {
    raise Limit("work_limit must be 1..16777216")
  }
  let n = method.length()
  let mut current = Array::make(n + 1, false)
  current[0] = true
  let work = Ref(0)
  for atom in self.atoms {
    let next = Array::make(n + 1, false)
    match atom {
      Star =>
        for j in 0..<(n + 1) {
          spend(work, work_limit)
          next[j] = current[j] || (j > 0 && next[j - 1] && method[j - 1] != 47)
        }
      Choices(words) =>
        for j in 0..<(n + 1) {
          spend(work, work_limit)
          if !current[j] {
            continue
          }
          for word in words {
            if word.length() > n - j {
              continue
            }
            let mut equal = true
            for k in 0..<word.length() {
              spend(work, work_limit)
              if word[k] != method[j + k] {
                equal = false
                break
              }
            }
            if equal {
              next[j + word.length()] = true
            }
          }
        }
      _ =>
        for j in 1..<(n + 1) {
          spend(work, work_limit)
          if !current[j - 1] {
            continue
          }
          let c = method[j - 1].to_int()
          let matched = match atom {
            Literal(v) => v == c
            Any => c != 47
            Class(negated, ranges) => {
              let mut found = false
              for (lo, hi) in ranges {
                spend(work, work_limit)
                if c >= lo && c <= hi {
                  found = true
                  break
                }
              }
              c != 47 && (if negated { !found } else { found })
            }
            Star | Choices(_) => false
          }
          next[j] = matched
        }
    }
    current = next
  }
  current[n]
}

///|
pub fn matches(
  pattern : String,
  method : String,
  work_limit? : Int = 1000000,
) -> Bool raise OscError {
  compile_pattern(pattern).matches(method, work_limit~)
}
