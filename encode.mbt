///|
fn argument_tag(arg : Argument) -> Char raise OscError {
  match arg {
    I32(_) => 'i'
    F32(_) => 'f'
    Text(_) => 's'
    Blob(_) => 'b'
    I64(_) => 'h'
    F64(_) => 'd'
    Time(_) => 't'
    Symbol(_) => 'S'
    Character(_) => 'c'
    Rgba(_) => 'r'
    Midi(_) => 'm'
    True => 'T'
    False => 'F'
    Nil => 'N'
    Impulse => 'I'
    Array(_) => raise Invalid("array requires recursive tag collection", 0)
  }
}

///|
fn write_argument(w : Writer, arg : Argument) -> Unit raise OscError {
  match arg {
    I32(v) => w.word(v.reinterpret_as_uint())
    F32(v) => w.word(v)
    Text(v) | Symbol(v) => w.text(v)
    Blob(v) => w.blob(v)
    I64(v) => w.wide(v.reinterpret_as_uint64())
    F64(v) => w.wide(v)
    Time(v) => {
      w.word(v.seconds)
      w.word(v.fraction)
    }
    Character(v) => {
      if v < 0 || v > 127 {
        raise Invalid("non-ASCII character argument", 0)
      }
      w.word(v.reinterpret_as_uint())
    }
    Rgba(v) | Midi(v) => w.word(v)
    True | False | Nil | Impulse => ()
    Array(_) => raise Invalid("array requires recursive payload writing", 0)
  }
}

///|
fn encode_message_budget(
  message : Message,
  limits : Limits,
  budget : Budget,
) -> Bytes raise OscError {
  validate_address(message.address)
  let tags : Array[Char] = [',']
  collect_tags(message.arguments, tags, 1, limits, budget)
  let w = Writer::{ out: [], limits, }
  w.text(message.address)
  w.text(String::from_array(tags[:]))
  write_arguments(w, message.arguments)
  Bytes::from_array(w.out)
}

///|
pub fn encode_message(
  message : Message,
  limits~ : Limits = Limits::default(),
) -> Bytes raise OscError {
  limits.validate()
  encode_message_budget(message, limits, Budget::{ args: 0, nodes: 0, })
}
