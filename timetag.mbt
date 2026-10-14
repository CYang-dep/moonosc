///|
pub fn TimeTag::immediate() -> TimeTag {
  { seconds: 0U, fraction: 1U, }
}

///|
pub fn TimeTag::is_immediate(self : TimeTag) -> Bool {
  self.seconds == 0U && self.fraction == 1U
}

///|
pub fn TimeTag::bits(self : TimeTag) -> UInt64 {
  (self.seconds.to_uint64() << 32) | self.fraction.to_uint64()
}

///|
pub fn TimeTag::from_bits(bits : UInt64) -> TimeTag {
  { seconds: (bits >> 32).to_uint(), fraction: bits.to_uint(), }
}

///|
/// Era 0 only, floors nanoseconds to the preceding 2^-32-second tick.
pub fn TimeTag::from_unix(
  seconds : Int64,
  nanoseconds~ : Int32 = 0,
) -> TimeTag raise OscError {
  if seconds < -2208988800L || seconds > 2085978495L {
    raise Invalid("Unix seconds outside NTP era 0", 0)
  }
  if nanoseconds < 0 || nanoseconds >= 1000000000 {
    raise Invalid("nanoseconds must be 0..999999999", 0)
  }
  let t = TimeTag::{
    seconds: (seconds + 2208988800L).reinterpret_as_uint64().to_uint(),
    fraction: ((nanoseconds.to_uint64() << 32) / 1000000000UL).to_uint(),
  }
  if t.is_immediate() {
    raise Invalid("timestamp collides with OSC immediate sentinel", 0)
  }
  t
}

///|
pub fn TimeTag::to_unix(self : TimeTag) -> (Int64, Int32) raise OscError {
  if self.is_immediate() {
    raise Invalid("immediate is not an absolute timestamp", 0)
  }
  (
    self.seconds.to_int64() - 2208988800L,
    ((self.fraction.to_uint64() * 1000000000UL) >> 32).to_int(),
  )
}

///|
pub fn TimeTag::resolve(
  self : TimeTag,
  now : TimeTag,
) -> TimeTag raise OscError {
  if now.is_immediate() {
    raise Invalid("now must be an absolute era-0 timetag", 0)
  }
  if self.is_immediate() {
    now
  } else {
    self
  }
}

///|
pub fn TimeTag::add_ticks(
  self : TimeTag,
  ticks : UInt64,
) -> TimeTag raise OscError {
  if self.is_immediate() {
    raise Invalid("cannot add to immediate", 0)
  }
  let bits = self.bits()
  if ticks > 0xffffffffffffffffUL - bits {
    raise Invalid("NTP era overflow", 0)
  }
  let out = TimeTag::from_bits(bits + ticks)
  if out.is_immediate() {
    raise Invalid("timestamp collides with immediate sentinel", 0)
  }
  out
}

///|
pub fn TimeTag::distance_ticks(
  self : TimeTag,
  later : TimeTag,
) -> UInt64 raise OscError {
  if self.is_immediate() || later.is_immediate() || later.bits() < self.bits() {
    raise Invalid("ordered absolute timetags required", 0)
  }
  later.bits() - self.bits()
}
