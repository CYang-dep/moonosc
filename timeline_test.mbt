///|
test "nested immediate inherits bundle time with wire ordering" {
  let now = @moonosc.TimeTag::from_unix(0L)
  let later = @moonosc.TimeTag::from_unix(2L)
  let m = @moonosc.Message::{ address: "/x", arguments: [@moonosc.I32(7)], }
  let packet = @moonosc.Bundle(later, [
    @moonosc.Message(m),
    @moonosc.Bundle(@moonosc.TimeTag::immediate(), [@moonosc.Message(m)]),
  ])
  let events = @moonosc.flatten(packet, now)
  assert_eq(events.map(x => x.due), [later, later])
  assert_eq(events.map(x => x.order), [0, 1])
  m.arguments.clear()
  assert_eq(events[0].message.arguments.length(), 1)
}

///|
test "nested earlier absolute bundle is rejected" {
  let now = @moonosc.TimeTag::from_unix(0L)
  let packet = @moonosc.Bundle(@moonosc.TimeTag::from_unix(2L), [
    @moonosc.Bundle(now, []),
  ])
  assert_true(
    try {
      ignore(@moonosc.flatten(packet, now))
      false
    } catch {
      _ => true
    },
  )
}
