///|
test "extended tags arrays and exact special floating bits" {
  let args : Array[@moonosc.Argument] = [
    @moonosc.I64(-9223372036854775807L),
    @moonosc.F64(0x7ff8000000000042UL),
    @moonosc.Time({ seconds: 123U, fraction: 456U, }),
    @moonosc.Symbol("s"),
    @moonosc.Character(65),
    @moonosc.Rgba(0xff00aa22U),
    @moonosc.Midi(0x00903c7fU),
    @moonosc.True,
    @moonosc.False,
    @moonosc.Nil,
    @moonosc.Impulse,
    @moonosc.Array([@moonosc.Array([]), @moonosc.I32(7)]),
    @moonosc.F32(0x7fc00042U),
  ]
  let m = @moonosc.Message::{ address: "/extended", arguments: args, }
  assert_eq(@moonosc.decode_message(@moonosc.encode_message(m)), m)
}

///|
test "array syntax and character domain rejection" {
  for
    bytes in [
      b"/x\x00\x00,]\x00\x00", b"/x\x00\x00,[\x00\x00", b"/x\x00\x00,c\x00\x00\x00\x00\x01\x00",
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
  let limits = @moonosc.Limits::{ ..@moonosc.Limits::default(), arguments: 1, }
  let m = @moonosc.Message::{
    address: "/x",
    arguments: [@moonosc.Array([@moonosc.Nil])],
  }
  assert_true(
    try {
      ignore(@moonosc.encode_message(m, limits~))
      false
    } catch {
      _ => true
    },
  )
}
