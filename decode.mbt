///|
fn decode_message_reader(
  r : Reader,
  limits : Limits,
  budget : Budget,
) -> Message raise OscError {
  let address = r.text(limits)
  validate_address(address)
  let tags = r.text(limits)
  if tags.length() == 0 || tags[0] != 44 {
    raise Invalid("missing type-tag comma", r.pos)
  }
  let arguments = read_arguments(r, tags, Ref::new(1), 1, limits, budget, false)
  if r.pos != r.end {
    raise Invalid("trailing message bytes", r.pos)
  }
  { address, arguments, }
}

///|
pub fn decode_message(
  bytes : Bytes,
  limits? : Limits = Limits::default(),
) -> Message raise OscError {
  limits.validate()
  if bytes.length() > limits.packet_bytes {
    raise Limit("packet bytes")
  }
  if bytes.length() % 4 != 0 {
    raise Invalid("packet not 4-byte aligned", bytes.length())
  }
  decode_message_reader(
    Reader::{ data: bytes, pos: 0, end: bytes.length(), },
    limits,
    Budget::{ args: 0, nodes: 0, },
  )
}
