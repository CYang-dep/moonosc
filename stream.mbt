///|
/// Size-prefix framing only: returned frames still require decode().
pub struct SizeFramer {
  priv mut pending : Array[Byte]
  priv max_frame : Int
  priv max_feed : Int
  priv max_frames : Int
}

///|
pub fn SizeFramer::new(
  max_frame? : Int = 1048576,
  max_feed? : Int = 16777216,
  max_frames? : Int = 4096,
) -> SizeFramer raise OscError {
  if max_frame < 4 ||
    max_frame > 16777216 ||
    max_feed < 1 ||
    max_feed > 67108864 ||
    max_frames < 1 ||
    max_frames > 65536 {
    raise Limit("invalid stream budgets")
  }
  { pending: [], max_frame, max_feed, max_frames, }
}

///|
/// Entire feed is transactional, including completed frames before a bad header.
/// On failure no input is accepted: retry corrected bytes or explicitly reset().
pub fn SizeFramer::feed(
  self : SizeFramer,
  chunk : Bytes,
) -> Array[Bytes] raise OscError {
  if chunk.length() > self.max_feed {
    raise Limit("stream feed bytes")
  }
  let data = self.pending.copy()
  for b in chunk {
    data.push(b)
  }
  let out : Array[Bytes] = []
  let mut offset = 0
  while data.length() - offset >= 4 {
    let mut size = 0U
    for i in 0..<4 {
      size = (size << 8) | data[offset + i].to_uint()
    }
    if size == 0U || size % 4U != 0U {
      raise Invalid("unaligned or empty stream frame", offset)
    }
    if size > self.max_frame.reinterpret_as_uint() {
      raise Limit("stream frame bytes")
    }
    let n = size.reinterpret_as_int()
    if data.length() - offset - 4 < n {
      break
    }
    if out.length() >= self.max_frames {
      raise Limit("stream output frames")
    }
    let frame : Array[Byte] = []
    for i in (offset + 4)..<(offset + 4 + n) {
      frame.push(data[i])
    }
    out.push(Bytes::from_array(frame))
    offset += 4 + n
  }
  let tail : Array[Byte] = []
  for i in offset..<data.length() {
    tail.push(data[i])
  }
  self.pending = tail
  out
}

///|
pub fn SizeFramer::finish(self : SizeFramer) -> Unit raise OscError {
  if !self.pending.is_empty() {
    raise Invalid("truncated size-prefix stream", self.pending.length())
  }
}

///|
pub fn SizeFramer::buffered(self : SizeFramer) -> Int {
  self.pending.length()
}

///|
pub fn SizeFramer::reset(self : SizeFramer) -> Unit {
  self.pending = []
}

///|
pub fn size_frame(
  bytes : Bytes,
  max_frame? : Int = 1048576,
) -> Bytes raise OscError {
  if max_frame < 4 || max_frame > 16777216 {
    raise Limit("invalid frame budget")
  }
  if bytes.is_empty() || bytes.length() % 4 != 0 {
    raise Invalid("unaligned or empty stream frame", 0)
  }
  if bytes.length() > max_frame {
    raise Limit("stream frame bytes")
  }
  let n = bytes.length().reinterpret_as_uint()
  let out : Array[Byte] = []
  for shift in [24, 16, 8, 0] {
    out.push((n >> shift).to_byte())
  }
  for b in bytes {
    out.push(b)
  }
  Bytes::from_array(out)
}
