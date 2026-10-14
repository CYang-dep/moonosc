///|
test "size framing accepts every split and multiple packets" {
  let raw = @moonosc.encode(
    @moonosc.Message({ address: "/x", arguments: [I32(42)], }),
  )
  let wire = @moonosc.size_frame(raw)
  for split in 0..<=wire.length() {
    let f = @moonosc.SizeFramer::new()
    let out = f.feed(wire[:split].to_owned())
    let rest = f.feed(wire[split:].to_owned())
    assert_eq(out.length() + rest.length(), 1)
    if out.length() == 1 {
      assert_eq(out[0], raw)
    } else {
      assert_eq(rest[0], raw)
    }
    f.finish()
  }
  let f = @moonosc.SizeFramer::new()
  assert_eq(f.feed(wire + wire), [raw, raw])
}

///|
test "bad trailing header rolls back entire feed" {
  let f = @moonosc.SizeFramer::new()
  let wire = b"\x00\x00\x00\x04abcd"
  assert_true(
    try {
      ignore(f.feed(wire + b"\x00\x00\x00\x03"))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(f.buffered(), 0)
  assert_eq(f.feed(wire), [b"abcd"])
  ignore(f.feed(b"\x00"))
  assert_true(
    try {
      f.finish()
      false
    } catch {
      _ => true
    },
  )
  f.reset()
  f.finish()
}
