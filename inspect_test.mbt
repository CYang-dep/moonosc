///|
test "hex codec validates canonical alphabet offsets and limits" {
  assert_eq(@moonosc.hex_encode(@moonosc.hex_decode("00aAFF")), "00aaff")
  assert_true(
    try {
      ignore(@moonosc.hex_decode("0x"))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonosc.hex_decode("0011", max_bytes=1))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonosc.hex_decode("0"))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "summary includes nested arrays blobs and wire depth" {
  let p = @moonosc.Bundle(@moonosc.TimeTag::immediate(), [
    @moonosc.Message({
      address: "/x",
      arguments: [Array([Blob(b"abcd"), I32(1)])],
    }),
  ])
  let s = @moonosc.summarize(p)
  assert_eq(s.messages, 1)
  assert_eq(s.bundles, 1)
  assert_eq(s.arguments, 3)
  assert_eq(s.array_arguments, 1)
  assert_eq(s.blob_bytes, 4)
  assert_eq(s.max_depth, 2)
  assert_eq(s.wire_bytes, @moonosc.encode(p).length())
}
