///|
fn decode_message_reader(r : Reader, limits : Limits) -> Message raise OscError {
  let address = r.text(limits)
  validate_address(address)
  let tags = r.text(limits)
  if tags.length() == 0 || tags[0] != 44 {
    raise Invalid("missing type-tag comma", r.pos)
  }
  if tags.length() - 1 > limits.arguments {
    raise Limit("arguments")
  }
  let arguments : Array[Argument] = []
  for i in 1..<tags.length() {
    let arg = match tags[i].to_int() {
      105 => I32(r.word().reinterpret_as_int())
      102 => F32(r.word())
      115 => Text(r.text(limits))
      98 => Blob(r.blob(limits))
      _ => raise Invalid("unsupported type tag", i)
    }
    arguments.push(arg)
  }
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
  )
}
