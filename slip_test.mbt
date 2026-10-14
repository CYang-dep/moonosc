///|
test "SLIP handles every split across escape pairs" {
  let raw = b"\xc0\xdb\x00\xff"
  let wire = @moonosc.slip_frame(raw)
  assert_eq(wire, b"\xc0\xdb\xdc\xdb\xdd\x00\xff\xc0")
  for split in 0..<=wire.length() {
    let f = @moonosc.SlipFramer::new()
    let a = f.feed(wire[:split].to_owned())
    let b = f.feed(wire[split:].to_owned())
    assert_eq(a.length() + b.length(), 1)
    if a.length() == 1 {
      assert_eq(a[0], raw)
    } else {
      assert_eq(b[0], raw)
    }
    f.finish()
  }
}

///|
test "SLIP rollback retains split escape and resets explicitly" {
  let f = @moonosc.SlipFramer::new()
  ignore(f.feed(b"abc\xdb"))
  assert_true(
    try {
      ignore(f.feed(b"\x00"))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(f.buffered(), 3)
  assert_eq(f.feed(b"\xdc\xc0"), [b"abc\xc0"])
  assert_eq(f.feed(b"\xc0\xc0"), [])
  f.finish()
  ignore(f.feed(b"\xdb"))
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
