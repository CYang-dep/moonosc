///|
test "cancel every heap position preserves sorted polling" {
  let now = @moonosc.TimeTag::from_unix(0L)
  let msg = @moonosc.Message::{ address: "/cue", arguments: [], }
  for removed in 0..<31 {
    let q = @moonosc.Scheduler::new()
    for i in 0..<31 {
      let second = i * 17 % 31
      ignore(
        q.enqueue(
          @moonosc.Bundle(@moonosc.TimeTag::from_unix(second.to_int64()), [
            @moonosc.Message(msg),
          ]),
          now,
        ),
      )
    }
    assert_true(q.cancel((removed + 1).to_uint64()))
    assert_true(!q.cancel((removed + 1).to_uint64()))
    let events = q.poll(@moonosc.TimeTag::from_unix(31L))
    assert_eq(events.length(), 30)
    for i in 1..<events.length() {
      assert_true(events[i - 1].due.bits() <= events[i].due.bits())
    }
  }
}

///|
test "late cutoff is exclusive and clear preserves identities" {
  let q = @moonosc.Scheduler::new()
  let now = @moonosc.TimeTag::from_unix(0L)
  let packet = @moonosc.Message({ address: "/x", arguments: [], })
  ignore(q.enqueue(packet, now))
  ignore(
    q.enqueue(@moonosc.Bundle(@moonosc.TimeTag::from_unix(1L), [packet]), now),
  )
  assert_eq(
    q.discard_before(@moonosc.TimeTag::from_unix(1L)).map(x => x.ticket),
    [1UL],
  )
  assert_eq(q.clear(), 1)
  assert_eq(q.enqueue(packet, now), [3UL])
}
