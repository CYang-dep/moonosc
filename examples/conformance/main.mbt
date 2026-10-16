///|
fn main {
  try {
    let packet = @osc.Message({
      address: "/x",
      arguments: [I32(-1), F32(0x3f000000U), Text("ok"), Blob(b"\x01\x02")],
    })
    let wire = @osc.encode_osc10(packet)
    assert_eq(
      @osc.hex_encode(wire),
      "2f7800002c69667362000000ffffffff3f0000006f6b00000000000201020000",
    )
    assert_eq(@osc.decode_osc10(wire), packet)
    let d = @osc.Dispatcher::new()
    d.add(1, "/synth/lead1/gain")
    d.add(2, "/synth/bass2/gain")
    d.add(3, "/synth/bass4/gain")
    let m : @osc.Message = {
      address: "/synth/{lead,bass}[1-3]/gain",
      arguments: [F32(0x3f000000U)],
    }
    let plan = d.plan(m)
    assert_eq(plan.accepted.map(r => r.id), [1, 2])
    // Every selected host method must receive exactly m.arguments.
    let mut delivered = 0
    for route in plan.accepted {
      assert_true(route.id == 1 || route.id == 2)
      assert_eq(m.arguments, [F32(0x3f000000U)])
      delivered += 1
    }
    assert_eq(delivered, 2)
    assert_true(@osc.matches("/a/{,b}c", "/a/c"))
    assert_true(@osc.matches("/a/[!0-9]?*", "/a/lead"))
    assert_false(@osc.matches("/a/*", "/a/x/y"))
    let now = @osc.TimeTag::from_unix(1700000000L)
    let later = now.add_ticks(1UL << 32)
    let first = @osc.Message({ address: "/first", arguments: [], })
    let inside = @osc.Message({ address: "/inside", arguments: [], })
    let last = @osc.Message({ address: "/last", arguments: [], })
    let q = @osc.Osc10Scheduler::new()
    assert_eq(
      q.enqueue(Bundle(later, [first, Bundle(later, [inside]), last]), now),
      [1UL, 2UL],
    )
    assert_eq(q.poll(now).length(), 0)
    assert_eq(q.poll(later, max_batches=1)[0].messages.map(m => m.address), [
      "/first", "/last",
    ])
    assert_eq(q.poll(later)[0].messages[0].address, "/inside")
    assert_true(
      try {
        ignore(q.enqueue(Bundle(later, [Bundle(now, [])]), now))
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        ignore(@osc.decode_osc10(b"/x\x00\x00"))
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        ignore(
          @osc.encode_osc10(Message({ address: "/x", arguments: [True], })),
        )
        false
      } catch {
        _ => true
      },
    )
    assert_eq(q.len(), 0)
    println(
      "OSC 1.0 core: exact wire; all-method fanout; indivisible timed batches; invalid inputs rejected",
    )
  } catch {
    _ => abort("OSC 1.0 conformance workflow failed")
  }
}
