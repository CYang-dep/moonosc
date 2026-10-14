///|
priv struct Reader {
  data : Bytes
  mut pos : Int32
  end : Int32
}

///|
fn Reader::need(self : Reader, n : Int32) -> Unit raise OscError {
  if n < 0 || n > self.end - self.pos {
    raise Invalid("truncated payload", self.pos)
  }
}

///|
fn Reader::word(self : Reader) -> UInt32 raise OscError {
  self.need(4)
  let p = self.pos
  self.pos += 4
  (self.data[p].to_uint() << 24) |
  (self.data[p + 1].to_uint() << 16) |
  (self.data[p + 2].to_uint() << 8) |
  self.data[p + 3].to_uint()
}

///|
fn Reader::wide(self : Reader) -> UInt64 raise OscError {
  let hi = self.word().to_uint64()
  let lo = self.word().to_uint64()
  (hi << 32) | lo
}

///|
fn Reader::padding(self : Reader, size : Int32) -> Unit raise OscError {
  let n = (4 - size % 4) % 4
  self.need(n)
  for _ in 0..<n {
    if self.data[self.pos] != 0 {
      raise Invalid("nonzero padding", self.pos)
    }
    self.pos += 1
  }
}

///|
fn Reader::text(self : Reader, limits : Limits) -> String raise OscError {
  let start = self.pos
  let chars : Array[Char] = []
  while true {
    self.need(1)
    let b = self.data[self.pos].to_int()
    self.pos += 1
    if b == 0 {
      break
    }
    if b > 127 {
      raise Invalid("non-ASCII OSC string", self.pos - 1)
    }
    if chars.length() >= limits.string_bytes {
      raise Limit("string bytes")
    }
    chars.push(b.to_char().unwrap())
  }
  self.padding(self.pos - start)
  String::from_array(chars[:])
}

///|
fn Reader::blob(self : Reader, limits : Limits) -> Bytes raise OscError {
  let n = self.word().reinterpret_as_int()
  if n < 0 {
    raise Invalid("negative blob length", self.pos - 4)
  }
  if n > limits.blob_bytes {
    raise Limit("blob bytes")
  }
  self.need(n)
  let out = Bytes::from_array(Array::makei(n, i => self.data[self.pos + i]))
  self.pos += n
  self.padding(n)
  out
}
