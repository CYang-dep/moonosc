///|
test "256 deterministic roundtrips and every truncated message prefix" {
  for i in 0..<256 {
    let args : Array[@moonosc.Argument] = [
      I32(i * 7919 - 1000000),
      F32(i.reinterpret_as_uint() * 0x9e3779b9U),
      F64(i.to_uint64() * 0x100000001UL),
      I64(i.to_int64() - 128L),
      Text("text"),
      Blob(Bytes::from_array(Array::makei(i % 17, j => j.to_byte()))),
      Array([True, False, Nil, Impulse]),
      Character(i % 128),
      Rgba(i.reinterpret_as_uint()),
      Midi(0x01020304U),
    ]
    let m = @moonosc.Message::{ address: "/check", arguments: args, }
    let raw = @moonosc.encode_message(m)
    assert_eq(@moonosc.decode_message(raw), m)
    for n in 0..<raw.length() {
      assert_true(
        try {
          ignore(@moonosc.decode(raw[:n].to_owned()))
          false
        } catch {
          _ => true
        },
      )
    }
    let packet = @moonosc.Bundle(
      @moonosc.TimeTag::from_bits(i.to_uint64() << 32),
      [@moonosc.Message(m)],
    )
    assert_eq(@moonosc.decode(@moonosc.encode(packet)), packet)
    assert_eq(@moonosc.parse_json(@moonosc.to_json(packet).stringify()), packet)
  }
}

///|
fn tiny_oracle(pattern : String, path : String, i : Int, j : Int) -> Bool {
  if i == pattern.length() {
    return j == path.length()
  }
  if pattern[i] == 42 {
    tiny_oracle(pattern, path, i + 1, j) ||
    (j < path.length() && path[j] != 47 && tiny_oracle(pattern, path, i, j + 1))
  } else {
    j < path.length() &&
    (pattern[i] == path[j] || (pattern[i] == 63 && path[j] != 47)) &&
    tiny_oracle(pattern, path, i + 1, j + 1)
  }
}

///|
test "wildcard DP agrees with a short recursive oracle on 240 pairs" {
  let patterns = [
    "/a", "/?", "/*", "/a*", "/*a", "/*?", "/?*?", "/a/**", "/a/?*", "/a*b", "/**b*",
    "/a/*/b",
  ]
  let paths = [
    "/a", "/b", "/aa", "/ab", "/ba", "/bb", "/aaa", "/aab", "/aba", "/abb", "/baa",
    "/bab", "/bba", "/bbb", "/a/a", "/a/b", "/a/ab", "/a/a/b", "/a/b/b", "/b/a",
  ]
  for p in patterns {
    for path in paths {
      assert_eq(@moonosc.matches(p, path), tiny_oracle(p, path, 0, 0))
    }
  }
}

///|
test "512 queue mutations agree with a scan-based reference model" {
  let q = @moonosc.Scheduler::new(capacity=1024)
  let now = @moonosc.TimeTag::from_unix(0L)
  let pending : Array[(UInt64, Int)] = []
  let mut seed = 12345U
  for step in 0..<512 {
    seed = seed * 1664525U + 1013904223U
    let due = (seed % 100U).reinterpret_as_int()
    let ticket = q.enqueue(
        @moonosc.Bundle(@moonosc.TimeTag::from_unix(due.to_int64()), [
          @moonosc.Message({ address: "/cue", arguments: [I32(step)], }),
        ]),
        now,
      )[0]
    pending.push((ticket, due))
    if step % 5 == 0 && !pending.is_empty() {
      let at = (seed % pending.length().reinterpret_as_uint()).reinterpret_as_int()
      let (id, _) = pending.remove(at)
      assert_true(q.cancel(id))
    }
    if step % 7 == 0 {
      let events = q.poll(@moonosc.TimeTag::from_unix(50L), max_count=3)
      for event in events {
        let mut best = 0
        for i in 1..<pending.length() {
          if pending[i].1 < pending[best].1 ||
            (pending[i].1 == pending[best].1 && pending[i].0 < pending[best].0) {
            best = i
          }
        }
        let (id, time) = pending.remove(best)
        assert_eq(event.ticket, id)
        assert_eq(event.due, @moonosc.TimeTag::from_unix(time.to_int64()))
      }
    }
    assert_eq(q.len(), pending.length())
  }
  let events = q.poll(@moonosc.TimeTag::from_unix(100L))
  assert_eq(events.length(), pending.length())
  for i in 1..<events.length() {
    assert_true(events[i - 1].due.bits() <= events[i].due.bits())
    if events[i - 1].due == events[i].due {
      assert_true(events[i - 1].ticket < events[i].ticket)
    }
  }
}

///|
test "malformed wire and resource limits fail deterministically" {
  for
    raw in [
      b"/x\x00\x01,i\x00\x00\x00\x00\x00\x00", b"/x\x00\x00,z\x00\x00", b"/x\x00\x00,b\x00\x00\xff\xff\xff\xff",
      b"#bundle\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00",
    ] {
    assert_true(
      try {
        ignore(@moonosc.decode(raw))
        false
      } catch {
        _ => true
      },
    )
  }
  let limits = @moonosc.Limits::{ ..@moonosc.Limits::default(), arguments: 1, }
  assert_true(
    try {
      ignore(
        @moonosc.encode(
          @moonosc.Message({ address: "/x", arguments: [Array([True])], }),
          limits~,
        ),
      )
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonosc.matches("/*/*/*", "/a/b/c", work_limit=2))
      false
    } catch {
      _ => true
    },
  )
}
