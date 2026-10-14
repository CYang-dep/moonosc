///|
test "nested bundle independent boundary and exact header vector" {
  let immediate = @moonosc.TimeTag::{ seconds: 0U, fraction: 1U, }
  assert_eq(
    @moonosc.encode(@moonosc.Bundle(immediate, [])),
    b"#bundle\x00\x00\x00\x00\x00\x00\x00\x00\x01",
  )
  let p = @moonosc.Bundle(immediate, [
    @moonosc.Message({ address: "/x", arguments: [@moonosc.I32(2)], }),
    @moonosc.Bundle(immediate, []),
  ])
  assert_eq(@moonosc.decode(@moonosc.encode(p)), p)
}

///|
test "bundle child cannot consume sibling bytes" {
  let bytes = b"#bundle\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x04/x\x00\x00,\x00\x00\x00"
  assert_true(
    try {
      ignore(@moonosc.decode(bytes))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "packet aggregate and recursive depth budgets" {
  let t = @moonosc.TimeTag::{ seconds: 0U, fraction: 1U, }
  let p = @moonosc.Bundle(t, [@moonosc.Bundle(t, [])])
  let limits = @moonosc.Limits::{ ..@moonosc.Limits::default(), depth: 1, }
  assert_true(
    try {
      ignore(@moonosc.encode(p, limits~))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonosc.decode(@moonosc.encode(p), limits~))
      false
    } catch {
      _ => true
    },
  )
  let limits = @moonosc.Limits::{ ..@moonosc.Limits::default(), elements: 1, }
  assert_true(
    try {
      ignore(@moonosc.encode(p, limits~))
      false
    } catch {
      _ => true
    },
  )
}
