///|
fn main {
  try {
    let now = @osc.TimeTag::from_unix(1700000000L)
    let later = now.add_ticks(1UL << 32)
    let packet = @osc.Bundle(later, [
      @osc.Message({ address: "/screen/show", arguments: [Text("scene-1")], }),
      @osc.Bundle(later, [
        @osc.Message({ address: "/light/color", arguments: [Text("33ccff")], }),
      ]),
      @osc.Message({ address: "/screen/commit", arguments: [], }),
    ])
    let queue = @osc.Osc10Scheduler::new()
    assert_eq(queue.enqueue(packet, now), [1UL, 2UL])
    assert_eq(queue.poll(now).length(), 0)
    assert_eq(
      queue.poll(later, max_batches=1)[0].messages.map(m => m.address),
      ["/screen/show", "/screen/commit"],
    )
    assert_eq(queue.poll(later)[0].messages[0].address, "/light/color")
    println("media: OSC 1.0 core; screen show/commit stay in one atomic batch")
  } catch {
    _ => abort("media workflow failed")
  }
}
