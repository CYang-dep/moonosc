///|
fn Budget::node(self : Budget, limits : Limits) -> Unit raise OscError {
  if self.nodes >= limits.elements {
    raise Limit("total packet nodes")
  }
  self.nodes += 1
}

///|
fn read_packet(
  r : Reader,
  limits : Limits,
  budget : Budget,
  depth : Int32,
) -> Packet raise OscError {
  if depth > limits.depth {
    raise Limit("bundle depth")
  }
  budget.node(limits)
  r.need(4)
  if r.data[r.pos] == 47 {
    return Message(decode_message_reader(r, limits, budget))
  }
  let start = r.pos
  if r.text(limits) != "#bundle" {
    raise Invalid("unknown packet prefix", start)
  }
  let time = TimeTag::{ seconds: r.word(), fraction: r.word(), }
  let children : Array[Packet] = []
  while r.pos < r.end {
    let n = r.word().reinterpret_as_int()
    if n <= 0 || n % 4 != 0 {
      raise Invalid("invalid bundle element size", r.pos - 4)
    }
    r.need(n)
    let child = Reader::{ data: r.data, pos: r.pos, end: r.pos + n, }
    children.push(read_packet(child, limits, budget, depth + 1))
    if child.pos != child.end {
      raise Invalid("unconsumed bundle child", child.pos)
    }
    r.pos += n
  }
  Bundle(time, children)
}

///|
pub fn decode(
  bytes : Bytes,
  limits~ : Limits = Limits::default(),
) -> Packet raise OscError {
  limits.validate()
  if bytes.length() > limits.packet_bytes {
    raise Limit("packet bytes")
  }
  if bytes.length() % 4 != 0 {
    raise Invalid("packet not 4-byte aligned", bytes.length())
  }
  read_packet(
    Reader::{ data: bytes, pos: 0, end: bytes.length(), },
    limits,
    Budget::{ args: 0, nodes: 0, },
    1,
  )
}

///|
fn write_packet(
  packet : Packet,
  limits : Limits,
  budget : Budget,
  depth : Int32,
) -> Bytes raise OscError {
  if depth > limits.depth {
    raise Limit("bundle depth")
  }
  budget.node(limits)
  match packet {
    Message(m) => encode_message_budget(m, limits, budget)
    Bundle(time, children) => {
      let w = Writer::{ out: [], limits, }
      w.text("#bundle")
      w.word(time.seconds)
      w.word(time.fraction)
      for child in children {
        let encoded = write_packet(child, limits, budget, depth + 1)
        w.room(4 + encoded.length())
        w.word(encoded.length().reinterpret_as_uint())
        for b in encoded {
          w.out.push(b)
        }
      }
      Bytes::from_array(w.out)
    }
  }
}

///|
pub fn encode(
  packet : Packet,
  limits~ : Limits = Limits::default(),
) -> Bytes raise OscError {
  limits.validate()
  write_packet(packet, limits, Budget::{ args: 0, nodes: 0, }, 1)
}
