///|
test "router fanout respects registration order and isolation" {
  let r = @moonosc.Router::new()
  r.add(7, "/synth/left")
  r.add(2, "/synth/right")
  r.add(9, "/light/red")
  assert_eq(r.resolve("/synth/*").map(x => x.id), [7, 2])
  let snapshot = r.snapshot()
  snapshot.clear()
  assert_eq(r.len(), 3)
  assert_true(r.remove(7))
  assert_false(r.remove(7))
  assert_eq(r.resolve("/synth/*").map(x => x.id), [2])
}

///|
test "router rejects duplicates and aggregate exhausted work" {
  let r = @moonosc.Router::new(capacity=1)
  r.add(1, "/x")
  assert_true(
    try {
      r.add(1, "/y")
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      r.add(2, "/y")
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(r.resolve("/*", work_limit=1))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(r.len(), 1)
}
