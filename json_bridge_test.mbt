///|
test "JSON schema is lossless across IEEE and signed 64 bit edge values" {
  let p = @moonosc.Bundle(@moonosc.TimeTag::immediate(), [
    @moonosc.Message({
      address: "/x",
      arguments: [
        I32(-1),
        F32(0x7fc01234U),
        I64(-9223372036854775808L),
        F64(0x8000000000000000UL),
        Time(@moonosc.TimeTag::from_bits(0xffffffffffffffffUL)),
        Blob(b"\xc0\xdb"),
        Array([
          True,
          False,
          Nil,
          Impulse,
          Text("hi"),
          Symbol("symbol"),
          Character(127),
          Rgba(0xffffffffU),
          Midi(0x01020304U),
        ]),
      ],
    }),
  ])
  let json = @moonosc.to_json(p)
  assert_eq(@moonosc.from_json(json), p)
  assert_eq(@moonosc.parse_json(json.stringify()), p)
}

///|
test "JSON rejects versions arity payload and numeric precision traps" {
  for
    input in [
      "[]", "[\"other\",[]]", "[\"moonosc/1\",[\"message\",\"/x\",[[\"h\",9007199254740993]]]]",
      "[\"moonosc/1\",[\"message\",\"/x\",[[\"T\",\"extra\"]]]]", "[\"moonosc/1\",[\"message\",\"/x\",[[\"f\",\"00\"]]]]",
    ] {
    assert_true(
      try {
        ignore(@moonosc.parse_json(input))
        false
      } catch {
        _ => true
      },
    )
  }
}
