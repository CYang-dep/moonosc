///|
/// RFC 1055 SLIP byte-stuffing, constrained to nonempty aligned OSC frames.
pub struct SlipFramer {
  priv mut pending : Array[Byte]
  priv mut escaped : Bool
  priv max_frame : Int
  priv max_feed : Int
  priv max_frames : Int
}

///|
pub fn SlipFramer::new(
  max_frame? : Int = 1048576,
  max_feed? : Int = 16777216,
  max_frames? : Int = 4096,
) -> SlipFramer raise OscError {
  if max_frame < 4 ||
    max_frame > 16777216 ||
    max_feed < 1 ||
    max_feed > 67108864 ||
    max_frames < 1 ||
    max_frames > 65536 {
    raise Limit("invalid SLIP budgets")
  }
  { pending: [], escaped: false, max_frame, max_feed, max_frames, }
}

///|
/// Empty ENDs are synchronization markers. Invalid escapes roll back the whole feed.
pub fn SlipFramer::feed(
  self : SlipFramer,
  chunk : Bytes,
) -> Array[Bytes] raise OscError {
  if chunk.length() > self.max_feed {
    raise Limit("SLIP feed bytes")
  }
  let data = self.pending.copy()
  let mut escaped = self.escaped
  let out : Array[Bytes] = []
  for i in 0..<chunk.length() {
    let b = chunk[i]
    if escaped {
      match b {
        0xdc => data.push(0xc0)
        0xdd => data.push(0xdb)
        _ => raise Invalid("invalid SLIP escape", i)
      }
      escaped = false
    } else if b == 0xdb {
      escaped = true
    } else if b == 0xc0 {
      if !data.is_empty() {
        if data.length() % 4 != 0 {
          raise Invalid("unaligned SLIP OSC frame", i)
        }
        if out.length() >= self.max_frames {
          raise Limit("SLIP output frames")
        }
        out.push(Bytes::from_array(data))
        data.clear()
      }
    } else {
      data.push(b)
    }
    if data.length() > self.max_frame {
      raise Limit("SLIP frame bytes")
    }
  }
  self.pending = data
  self.escaped = escaped
  out
}

///|
pub fn SlipFramer::finish(self : SlipFramer) -> Unit raise OscError {
  if self.escaped || !self.pending.is_empty() {
    raise Invalid("truncated SLIP stream", self.pending.length())
  }
}

///|
pub fn SlipFramer::buffered(self : SlipFramer) -> Int {
  self.pending.length()
}

///|
pub fn SlipFramer::reset(self : SlipFramer) -> Unit {
  self.pending = []
  self.escaped = false
}

///|
/// Adds leading and trailing END for synchronization; worst case 2*n+2 bytes.
pub fn slip_frame(
  bytes : Bytes,
  max_frame? : Int = 1048576,
) -> Bytes raise OscError {
  if max_frame < 4 || max_frame > 16777216 || bytes.length() > max_frame {
    raise Limit("SLIP frame bytes")
  }
  if bytes.is_empty() || bytes.length() % 4 != 0 {
    raise Invalid("unaligned or empty SLIP OSC frame", 0)
  }
  let out : Array[Byte] = [0xc0]
  for b in bytes {
    match b {
      0xc0 => {
        out.push(0xdb)
        out.push(0xdc)
      }
      0xdb => {
        out.push(0xdb)
        out.push(0xdd)
      }
      _ => out.push(b)
    }
  }
  out.push(0xc0)
  Bytes::from_array(out)
}
