///|
fn main {
  try {
    for i in 0..<128 {
      let m = @osc.Message({
        address: "/vector/" + i.to_string(),
        arguments: [
          I32(i * 7919 - 1),
          F32(0x3f000000U + i.reinterpret_as_uint()),
          Text("hello"),
          Blob(Bytes::from_array([0, 0xc0, 0xdb, i.to_byte()])),
          Array([True, Nil]),
        ],
      })
      println(@osc.hex_encode(@osc.encode(m)))
      println(
        @osc.hex_encode(
          @osc.encode(
            @osc.Bundle(@osc.TimeTag::from_bits(0x0123456789abcdefUL), [m]),
          ),
        ),
      )
    }
  } catch {
    _ => abort("reference vector workflow failed")
  }
}
