///|
test "decode OSC standard integer and float vector" {
  let m = @moonosc.decode_message(
    b"/x\x00\x00,if\x00\xff\xff\xff\xff\x3f\x80\x00\x00",
  )
  assert_eq(m.address, "/x")
  assert_eq(m.arguments, [@moonosc.I32(-1), @moonosc.F32(0x3f800000U)])
}

///|
test "decoder requires tags exact bytes and zero padding" {
  for
    bytes in [
      b"/x\x00\x00", b"/x\x00\x00i\x00\x00\x00", b"/x\x00\x00,q\x00\x00", b"/x\x00X,\x00\x00\x00",
      b"/x\x00\x00,\x00\x00\x00abcd",
    ] {
    assert_true(
      try {
        ignore(@moonosc.decode_message(bytes))
        false
      } catch {
        _ => true
      },
    )
  }
}
