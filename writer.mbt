///|
priv struct Writer {
  out : Array[Byte]
  limits : Limits
}

///|
fn Writer::room(self : Writer, count : Int) -> Unit raise OscError {
  if count < 0 || count > self.limits.packet_bytes - self.out.length() {
    raise Limit("encoded packet bytes")
  }
}

///|
fn Writer::word(self : Writer, value : UInt) -> Unit raise OscError {
  self.room(4)
  for shift in [24, 16, 8, 0] {
    self.out.push((value >> shift).to_byte())
  }
}

///|
fn Writer::wide(self : Writer, value : UInt64) -> Unit raise OscError {
  self.room(8)
  self.word((value >> 32).to_uint())
  self.word(value.to_uint())
}

///|
fn Writer::padding(self : Writer, size : Int) -> Unit raise OscError {
  let n = (4 - size % 4) % 4
  self.room(n)
  for _ in 0..<n {
    self.out.push(0)
  }
}

///|
fn Writer::text(self : Writer, text : String) -> Unit raise OscError {
  if !ascii_valid(text) {
    raise Invalid("OSC string requires non-NUL ASCII", self.out.length())
  }
  if text.length() > self.limits.string_bytes {
    raise Limit("string bytes")
  }
  self.room(text.length() + 1)
  for c in text.code_units() {
    self.out.push(c.to_byte())
  }
  self.out.push(0)
  self.padding(text.length() + 1)
}

///|
fn Writer::blob(self : Writer, bytes : Bytes) -> Unit raise OscError {
  if bytes.length() > self.limits.blob_bytes {
    raise Limit("blob bytes")
  }
  self.room(4 + bytes.length())
  self.word(bytes.length().reinterpret_as_uint())
  for b in bytes {
    self.out.push(b)
  }
  self.padding(bytes.length())
}
