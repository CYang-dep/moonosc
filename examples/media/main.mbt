///|
fn main {
  try {
    let now = @osc.TimeTag::from_unix(1700000000L)
    let later = now.add_ticks(1UL << 32)
    let packet = @osc.Bundle(later, [
      @osc.Message({ address: "/screen/show", arguments: [Text("scene-1")], }),
      @osc.Bundle(@osc.TimeTag::immediate(), [
        @osc.Message({
          address: "/light/color",
          arguments: [Rgba(0x33ccffffU)],
        }),
      ]),
    ])
    let queue = @osc.Scheduler::new()
    assert_eq(queue.enqueue(packet, now), [1UL, 2UL])
    assert_eq(queue.poll(now).length(), 0)
    assert_eq(queue.poll(later).map(e => e.message.address), [
      "/screen/show", "/light/color",
    ])
    println("media: nested immediate cue inherits parent time; 2 stable events")
  } catch {
    _ => abort("media workflow failed")
  }
}
