///|
test "writer produces canonical network bytes" {
  let w = Writer::{ out: [], limits: Limits::default(), }
  w.text("abc")
  w.word(0x12345678U)
  w.blob(b"xy")
  assert_eq(
    Bytes::from_array(w.out),
    b"abc\x00\x12\x34\x56\x78\x00\x00\x00\x02xy\x00\x00",
  )
}

///|
test "writer rejects invalid strings without output" {
  let w = Writer::{ out: [], limits: Limits::default(), }
  assert_true(
    try {
      w.text("é")
      false
    } catch {
      _ => true
    },
  )
  assert_eq(w.out.length(), 0)
}
