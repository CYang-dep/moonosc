///|
test "reader network order and exact padding" {
  let r = Reader::{ data: b"abcd\x00\x00\x00\x00", pos: 0, end: 8, }
  assert_eq(r.word(), 0x61626364U)
  assert_eq(r.text(Limits::default()), "")
  assert_eq(r.pos, 8)
  let r = Reader::{ data: b"a\x00\x00X", pos: 0, end: 4, }
  assert_true(
    try {
      ignore(r.text(Limits::default()))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "reader rejects blob overruns and negative lengths" {
  for bytes in [b"\xff\xff\xff\xff", b"\x00\x00\x00\x05x"] {
    let r = Reader::{ data: bytes, pos: 0, end: bytes.length(), }
    assert_true(
      try {
        ignore(r.blob(Limits::default()))
        false
      } catch {
        _ => true
      },
    )
  }
}
