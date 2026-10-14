///|
test "scheduler orders due time then stable tickets" {
  let q = @moonosc.Scheduler::new()
  let now = @moonosc.TimeTag::from_unix(0L)
  let m = @moonosc.Message::{ address: "/x", arguments: [], }
  let late = @moonosc.Bundle(@moonosc.TimeTag::from_unix(2L), [
    @moonosc.Message(m),
    @moonosc.Message(m),
  ])
  assert_eq(q.enqueue(late, now), [1UL, 2UL])
  assert_eq(q.enqueue(@moonosc.Message(m), now), [3UL])
  assert_eq(q.poll(now).map(x => x.ticket), [3UL])
  assert_eq(q.poll(@moonosc.TimeTag::from_unix(2L)).map(x => x.ticket), [
    1UL, 2UL,
  ])
  assert_eq(q.len(), 0)
}

///|
test "scheduler admission failures preserve state and ticket sequence" {
  let q = @moonosc.Scheduler::new(capacity=1)
  let now = @moonosc.TimeTag::from_unix(0L)
  let m = @moonosc.Message({ address: "/x", arguments: [], })
  assert_true(
    try {
      ignore(q.enqueue(@moonosc.Bundle(now, [m, m]), now))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(q.len(), 0)
  assert_eq(q.enqueue(m, now), [1UL])
  assert_eq(q.poll(now, max_count=0).length(), 0)
  assert_eq(q.next_due(), Some(now))
}
