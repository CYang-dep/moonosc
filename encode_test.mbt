///|
test "canonical message encoding matches hand-calculated vector" {
  let m = @moonosc.Message::{
    address: "/x",
    arguments: [@moonosc.I32(-1), @moonosc.F32(0x3f800000U)],
  }
  let bytes = @moonosc.encode_message(m)
  assert_eq(bytes, b"/x\x00\x00,if\x00\xff\xff\xff\xff\x3f\x80\x00\x00")
  assert_eq(@moonosc.decode_message(bytes), m)
}

///|
test "strings and all blob padding residues roundtrip" {
  for n in 0..<12 {
    let m = @moonosc.Message::{
      address: "/blob",
      arguments: [
        @moonosc.Text("hello"),
        @moonosc.Blob(Bytes::from_array(Array::make(n, 255))),
      ],
    }
    assert_eq(@moonosc.decode_message(@moonosc.encode_message(m)), m)
  }
}
