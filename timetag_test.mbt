///|
test "NTP Unix epoch and fractional conversion" {
  let t = @moonosc.TimeTag::from_unix(0L, nanoseconds=500000000)
  assert_eq(t.seconds, 2208988800U)
  assert_eq(t.fraction, 0x80000000U)
  assert_eq(t.to_unix(), (0L, 500000000))
  assert_eq(@moonosc.TimeTag::from_bits(t.bits()), t)
  assert_eq(t.distance_ticks(t.add_ticks(1UL)), 1UL)
}

///|
test "immediate resolution and era overflow are explicit" {
  let now = @moonosc.TimeTag::from_unix(12L)
  assert_eq(@moonosc.TimeTag::immediate().resolve(now), now)
  assert_true(
    try {
      ignore(@moonosc.TimeTag::immediate().to_unix())
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonosc.TimeTag::from_unix(2085978496L))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonosc.TimeTag::from_bits(0xffffffffffffffffUL).add_ticks(1UL))
      false
    } catch {
      _ => true
    },
  )
}
