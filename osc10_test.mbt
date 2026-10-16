///|
test "OSC10 core golden wire and exact required tags" {
  let message : @moonosc.Packet = Message({
    address: "/x",
    arguments: [I32(-1), F32(0x3f000000U), Text("ok"), Blob(b"\x01\x02")],
  })
  let wire = @moonosc.hex_decode(
    "2f7800002c69667362000000ffffffff3f0000006f6b00000000000201020000",
  )
  assert_eq(@moonosc.encode_osc10(message), wire)
  assert_eq(@moonosc.decode_osc10(wire), message)
  assert_eq(
    @moonosc.decode_osc10(
      @moonosc.encode_osc10(Message({ address: "/empty", arguments: [], })),
    ),
    Message({ address: "/empty", arguments: [], }),
  )
}

///|
test "OSC10 optional tags stay explicit and strict rejection never coerces" {
  for
    arg in [
      @moonosc.I64(1L),
      F64(0UL),
      Time(@moonosc.TimeTag::immediate()),
      Symbol("s"),
      Character(65),
      Rgba(0U),
      Midi(0U),
      True,
      False,
      Nil,
      Impulse,
      Array([]),
    ] {
    let packet : @moonosc.Packet = Message({ address: "/x", arguments: [arg], })
    assert_eq(@moonosc.decode(@moonosc.encode(packet)), packet)
    assert_true(
      try {
        ignore(@moonosc.encode_osc10(packet))
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        ignore(@moonosc.decode_osc10(@moonosc.encode(packet)))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "OSC10 every normative wildcard form and literal brace semantics" {
  for
    (pattern, yes, no) in [
      ("/a/?", "/a/x", "/a/xy"),
      ("/a/x*", "/a/x", "/a/y"),
      ("/a/[abc]", "/a/b", "/a/d"),
      ("/a/[a-c]", "/a/c", "/a/d"),
      ("/a/[!a-c]", "/a/z", "/a/b"),
      ("/a/[a-]", "/a/-", "/a/b"),
      ("/a/[a!]", "/a/!", "/a/b"),
      ("/a/{left,right}", "/a/right", "/a/le"),
      ("/a{,b}/gain", "/a/gain", "/c/gain"),
      ("/a{b,}/gain", "/a/gain", "/c/gain"),
      ("/a{}/gain", "/a/gain", "/ab/gain"),
      ("/a/{*,ok}", "/a/ok", "/a/no"),
      (
        "/synth/{lead,bass}[1-3]/*gain?", "/synth/lead2/postgainL", "/synth/lead4/postgainL",
      ),
    ] {
    assert_true(@moonosc.matches(pattern, yes))
    assert_false(@moonosc.matches(pattern, no))
  }
  assert_false(@moonosc.matches("/a/*", "/a/x/y"))
  assert_false(@moonosc.matches("/a/?", "/a/x/y"))
  assert_false(@moonosc.matches("/a/[!-z]", "/a/x/y"))
}

///|
test "OSC10 required dispatch reaches every matching method with same arguments" {
  let d = @moonosc.Dispatcher::new()
  d.add(1, "/synth/lead1/gain")
  d.add(2, "/synth/bass2/gain")
  d.add(3, "/synth/bass4/gain")
  let message : @moonosc.Message = {
    address: "/synth/{lead,bass}[1-3]/gain",
    arguments: [F32(0x3f000000U)],
  }
  let result = d.plan(message)
  assert_eq(result.accepted.map(r => r.id), [1, 2])
  assert_eq(result.rejected.length(), 0)
  assert_eq(d.plan({ address: "/none/*", arguments: [], }).accepted.length(), 0)
  let empty = @moonosc.Router::new()
  assert_true(
    try {
      ignore(empty.resolve("/a", work_limit=0))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "OSC10 strict nested time and pattern validation is not deferred to callbacks" {
  let now = @moonosc.TimeTag::from_unix(1700000000L)
  let future = now.add_ticks(1UL << 32)
  for
    packet in [
      @moonosc.Bundle(future, [Bundle(now, [])]),
      @moonosc.Bundle(future, [Bundle(@moonosc.TimeTag::immediate(), [])]),
      @moonosc.Message({ address: "/bad/[", arguments: [], }),
    ] {
    assert_true(
      try {
        ignore(@moonosc.encode_osc10(packet))
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        ignore(@moonosc.decode_osc10(@moonosc.encode(packet)))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_eq(
    @moonosc.plan_osc10(Bundle(future, [Bundle(future, [])]), now).length(),
    0,
  )
  assert_eq(
    @moonosc.plan_osc10(Message({ address: "/x", arguments: [], }), now)[0].due,
    now,
  )
  assert_eq(
    @moonosc.plan_osc10(
      Bundle(@moonosc.TimeTag::immediate(), [
        Message({ address: "/x", arguments: [], }),
      ]),
      now,
    )[0].due,
    now,
  )
}

///|
test "OSC10 bundles preserve direct-message atomic groups across nested bundles" {
  let now = @moonosc.TimeTag::from_unix(1700000000L)
  let packet : @moonosc.Packet = Bundle(now, [
    Message({ address: "/first", arguments: [], }),
    Bundle(now, [Message({ address: "/nested", arguments: [], })]),
    Message({ address: "/last", arguments: [], }),
  ])
  let batches = @moonosc.plan_osc10(packet, now)
  assert_eq(batches.length(), 2)
  assert_eq(batches[0].messages.map(m => m.address), ["/first", "/last"])
  assert_eq(batches[1].messages.map(m => m.address), ["/nested"])
  let q = @moonosc.Osc10Scheduler::new()
  assert_eq(q.enqueue(packet, now), [1UL, 2UL])
  let one = q.poll(now, max_batches=1)
  assert_eq(one.length(), 1)
  assert_eq(one[0].messages.length(), 2)
  assert_eq(q.len(), 1)
  assert_eq(q.poll(now)[0].messages[0].address, "/nested")
}

///|
test "OSC10 batch admission rollback snapshot and ticket lifecycle" {
  let now = @moonosc.TimeTag::from_unix(1700000000L)
  let future = now.add_ticks(1UL << 32)
  let args : Array[@moonosc.Argument] = [I32(1)]
  let msg : @moonosc.Packet = Message({ address: "/x", arguments: args, })
  let q = @moonosc.Osc10Scheduler::new(capacity=1)
  assert_eq(q.enqueue(Bundle(future, [msg, msg]), now), [1UL])
  args[0] = I32(999)
  assert_true(
    try {
      ignore(q.enqueue(msg, now))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(q.next_due(), Some(future))
  assert_eq(q.poll(now).length(), 0)
  assert_eq(q.poll(future, max_batches=0).length(), 0)
  let result = q.poll(future)
  assert_eq(result[0].messages[0].arguments, [I32(1)])
  assert_eq(result[0].messages[1].arguments, [I32(1)])
  assert_eq(q.enqueue(msg, now), [2UL])
  assert_true(q.cancel(2UL))
  assert_false(q.cancel(2UL))
  assert_eq(q.next_due(), None)
  assert_eq(q.enqueue(msg, now), [3UL])
  assert_eq(q.clear(), 1)
  assert_eq(q.enqueue(msg, now), [4UL])
  assert_eq(q.poll(future)[0].ticket, 4UL)
}

///|
test "OSC10 batch polling sorts due time then stable ticket and never drops late" {
  let now = @moonosc.TimeTag::from_unix(1700000000L)
  let later = now.add_ticks(1UL << 32)
  let msg : @moonosc.Packet = Message({ address: "/x", arguments: [], })
  let q = @moonosc.Osc10Scheduler::new()
  assert_eq(q.enqueue(Bundle(later, [msg]), now), [1UL])
  assert_eq(q.enqueue(msg, now), [2UL])
  assert_eq(q.enqueue(msg, now), [3UL])
  assert_eq(q.poll(later).map(x => x.ticket), [2UL, 3UL, 1UL])
  assert_true(
    try {
      ignore(q.poll(@moonosc.TimeTag::immediate()))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(q.poll(now, max_batches=-1))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "OSC10 rejects malformed wire rather than guessing legacy tags" {
  for
    hex in [
      "2f780000", // missing typetag
       "2f7800006900000000000001", // missing comma
       "2f7800002c7a0000", // unknown tag
       "2f7800012c000000", // nonzero address padding
       "2f7800002c620000ffffffff", // negative blob length
       "2f7800002c6200000000000201000001", // nonzero blob padding
       "2362756e646c65000000000000000001ffffffff", // negative child length
       "2362756e646c65000000000000000001000000082f780000", // child overrun
    ] {
    assert_true(
      try {
        ignore(@moonosc.decode_osc10(@moonosc.hex_decode(hex)))
        false
      } catch {
        _ => true
      },
    )
  }
  let wire = @moonosc.encode_osc10(
    Message({ address: "/x", arguments: [I32(3)], }),
  )
  for n in 0..<wire.length() {
    assert_true(
      try {
        ignore(@moonosc.decode_osc10(wire[0:n].to_owned()))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_eq(
    @moonosc.decode_osc10(
      @moonosc.hex_decode("2362756e646c65000000000000000001"),
    ),
    Bundle(@moonosc.TimeTag::immediate(), []),
  )
}

///|
test "OSC10 admission validates whole tree limits and illegal addresses before mutation" {
  let now = @moonosc.TimeTag::from_unix(1700000000L)
  let msg : @moonosc.Packet = Message({ address: "/x", arguments: [], })
  let q = @moonosc.Osc10Scheduler::new(capacity=1)
  assert_true(
    try {
      ignore(q.enqueue(Bundle(now, [msg, Bundle(now, [msg])]), now))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(q.len(), 0)
  let limits = @moonosc.Limits::default()
  assert_true(
    try {
      ignore(q.enqueue(Bundle(now, [msg]), now, limits={ ..limits, depth: 1, }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(q.enqueue(msg, now, limits={ ..limits, elements: 0, }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        q.enqueue(Message({ address: "/x", arguments: [I32(1)], }), now, limits={
          ..limits,
          arguments: 0,
        }),
      )
      false
    } catch {
      _ => true
    },
  )
  for
    address in [
      "/bad//x", "/bad/[", "/bad/{x", "/bad name", "/bad#name", "/中文",
    ] {
    assert_true(
      try {
        ignore(q.enqueue(Message({ address, arguments: [], }), now))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_eq(q.enqueue(msg, now), [1UL])
  let router = @moonosc.Router::new()
  for
    address in [
      "/", "/a/", "/a//b", "/a/*", "/a/?", "/a/[x]", "/a/{x,y}", "/a,b", "/a b",
      "/a#b", "/中文",
    ] {
    assert_true(
      try {
        router.add(1, address)
        false
      } catch {
        _ => true
      },
    )
  }
  assert_eq(router.len(), 0)
  assert_true(
    try {
      ignore(@moonosc.matches("/x/{,,,,,,,,,,,,}", "/x/a", work_limit=12))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "OSC10 batch queue agrees with independent sorted ticket model" {
  let now = @moonosc.TimeTag::from_unix(1700000000L)
  let q = @moonosc.Osc10Scheduler::new(capacity=128)
  let model : Array[(UInt64, UInt64)] = []
  for i in 0..<96 {
    let offset = (i * 17 % 13).to_uint64()
    let due = now.add_ticks(offset)
    let packet : @moonosc.Packet = Bundle(due, [
      Message({ address: "/first", arguments: [I32(i)], }),
      Message({ address: "/last", arguments: [I32(i)], }),
    ])
    let ticket = q.enqueue(packet, now)[0]
    model.push((offset, ticket))
  }
  for i in 0..<model.length() {
    if i % 5 == 0 {
      assert_true(q.cancel(model[i].1))
    }
  }
  model.sort_by(fn(a, b) {
    if a.0 < b.0 {
      -1
    } else if a.0 > b.0 {
      1
    } else if a.1 < b.1 {
      -1
    } else if a.1 > b.1 {
      1
    } else {
      0
    }
  })
  let expected = model.filter(x => (x.1 - 1UL) % 5UL != 0UL)
  let actual : Array[UInt64] = []
  for offset in 0..<13 {
    let due = now.add_ticks(offset.to_uint64())
    let ready = q.poll(due, max_batches=128)
    for batch in ready {
      assert_true(batch.due.bits() <= due.bits())
      assert_eq(batch.messages.map(m => m.address), ["/first", "/last"])
      assert_eq(batch.messages[0].arguments, batch.messages[1].arguments)
      actual.push(batch.ticket)
    }
  }
  assert_eq(actual, expected.map(x => x.1))
  assert_eq(q.len(), 0)
}
