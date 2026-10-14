///|
fn argument_tag(arg : Argument) -> Char raise OscError {
  match arg {
    I32(_) => 'i'
    F32(_) => 'f'
    Text(_) => 's'
    Blob(_) => 'b'
    _ => raise Invalid("unsupported argument", 0)
  }
}

///|
fn write_argument(w : Writer, arg : Argument) -> Unit raise OscError {
  match arg {
    I32(v) => w.word(v.reinterpret_as_uint())
    F32(v) => w.word(v)
    Text(v) => w.text(v)
    Blob(v) => w.blob(v)
    _ => raise Invalid("unsupported argument", w.out.length())
  }
}

///|
pub fn encode_message(
  message : Message,
  limits? : Limits = Limits::default(),
) -> Bytes raise OscError {
  limits.validate()
  validate_address(message.address)
  if message.arguments.length() > limits.arguments {
    raise Limit("arguments")
  }
  let tags : Array[Char] = [',']
  for arg in message.arguments {
    tags.push(argument_tag(arg))
  }
  let w = Writer::{ out: [], limits, }
  w.text(message.address)
  w.text(String::from_array(tags[:]))
  for arg in message.arguments {
    write_argument(w, arg)
  }
  Bytes::from_array(w.out)
}
