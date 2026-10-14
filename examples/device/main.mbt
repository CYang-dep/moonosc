///|
fn main {
  try {
    let packet = @osc.Message({
      address: "/device/level",
      arguments: [I32(42), Blob(b"\xc0\xdb")],
    })
    let wire = @osc.slip_frame(@osc.encode(packet))
    let stream = @osc.SlipFramer::new()
    let out : Array[@osc.Packet] = []
    for i in 0..<wire.length() {
      for frame in stream.feed(wire[i:i + 1].to_owned()) {
        out.push(@osc.decode(frame))
      }
    }
    stream.finish()
    assert_eq(out, [packet])
    let diagnostic = @osc.to_json(out[0]).stringify()
    assert_eq(@osc.parse_json(diagnostic), packet)
    println(
      "device: byte-by-byte SLIP reassembly and lossless diagnostic replay",
    )
  } catch {
    _ => abort("device workflow failed")
  }
}
