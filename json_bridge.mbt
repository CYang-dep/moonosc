///|
fn word_hex(value : UInt32) -> String raise OscError {
  let w = Writer::{ out: [], limits: Limits::default(), }
  w.word(value)
  hex_encode(Bytes::from_array(w.out))
}

///|
fn wide_hex(value : UInt64) -> String raise OscError {
  let w = Writer::{ out: [], limits: Limits::default(), }
  w.wide(value)
  hex_encode(Bytes::from_array(w.out))
}

///|
fn argument_json(arg : Argument) -> Json raise OscError {
  let tag = match arg {
    Array(_) => "["
    _ => argument_tag(arg).to_string()
  }
  match arg {
    Array(items) =>
      @json.to_json([
        @json.to_json("["),
        @json.to_json(items.map(argument_json)),
      ])
    True | False | Nil | Impulse => @json.to_json([@json.to_json(tag)])
    _ => {
      let value = match arg {
        I32(n) => word_hex(n.reinterpret_as_uint())
        F32(n) | Rgba(n) | Midi(n) => word_hex(n)
        I64(n) => wide_hex(n.reinterpret_as_uint64())
        F64(n) => wide_hex(n)
        Time(t) => wide_hex(t.bits())
        Character(c) => word_hex(c.reinterpret_as_uint())
        Text(s) | Symbol(s) => s
        Blob(b) => hex_encode(b, max_bytes=16777216)
        _ => abort("unreachable array or payloadless argument")
      }
      @json.to_json([@json.to_json(tag), @json.to_json(value)])
    }
  }
}

///|
fn packet_json(packet : Packet) -> Json raise OscError {
  match packet {
    Message(m) =>
      @json.to_json([
        @json.to_json("message"),
        @json.to_json(m.address),
        @json.to_json(m.arguments.map(argument_json)),
      ])
    Bundle(t, children) =>
      @json.to_json([
        @json.to_json("bundle"),
        @json.to_json(wide_hex(t.bits())),
        @json.to_json(children.map(packet_json)),
      ])
  }
}

///|
/// Versioned tagged-array schema. Integers and IEEE/NTP bits are fixed-width hex,
/// never JSON numbers: NaN payloads, signed zero and all 64-bit values survive.
pub fn to_json(
  packet : Packet,
  limits~ : Limits = Limits::default(),
) -> Json raise OscError {
  let validated = decode(encode(packet, limits~), limits~)
  @json.to_json([@json.to_json("moonosc/1"), packet_json(validated)])
}

///|
fn json_array(value : Json) -> Array[Json] raise OscError {
  match value {
    Json::Array(items) => items
    _ => raise Invalid("JSON array expected", 0)
  }
}

///|
fn json_string(value : Json) -> String raise OscError {
  match value {
    Json::String(s) => s
    _ => raise Invalid("JSON string expected", 0)
  }
}

///|
fn parse_hex_word(text : String) -> UInt32 raise OscError {
  if text.length() != 8 {
    raise Invalid("expected 8 hex digits", 0)
  }
  let bytes = hex_decode(text, max_bytes=4)
  Reader::{ data: bytes, pos: 0, end: 4, }.word()
}

///|
fn parse_hex_wide(text : String) -> UInt64 raise OscError {
  if text.length() != 16 {
    raise Invalid("expected 16 hex digits", 0)
  }
  let bytes = hex_decode(text, max_bytes=8)
  Reader::{ data: bytes, pos: 0, end: 8, }.wide()
}

///|
fn argument_from_json(
  value : Json,
  depth : Int32,
  limits : Limits,
  budget : Budget,
) -> Argument raise OscError {
  if depth > limits.depth {
    raise Limit("JSON argument depth")
  }
  budget.argument(limits)
  let items = json_array(value)
  if items.length() < 1 || items.length() > 2 {
    raise Invalid("JSON argument arity", 0)
  }
  let tag = json_string(items[0])
  if tag == "T" || tag == "F" || tag == "N" || tag == "I" {
    if items.length() != 1 {
      raise Invalid("payloadless JSON tag", 0)
    }
    return match tag {
      "T" => True
      "F" => False
      "N" => Nil
      _ => Impulse
    }
  }
  if items.length() != 2 {
    raise Invalid("JSON argument payload required", 0)
  }
  if tag == "[" {
    let children = json_array(items[1])
    if children.length() > limits.arguments - budget.args {
      raise Limit("JSON arguments")
    }
    return Array(
      children.map(x => argument_from_json(x, depth + 1, limits, budget)),
    )
  }
  let text = json_string(items[1])
  match tag {
    "i" => I32(parse_hex_word(text).reinterpret_as_int())
    "f" => F32(parse_hex_word(text))
    "h" => I64(parse_hex_wide(text).reinterpret_as_int64())
    "d" => F64(parse_hex_wide(text))
    "t" => Time(TimeTag::from_bits(parse_hex_wide(text)))
    "r" => Rgba(parse_hex_word(text))
    "m" => Midi(parse_hex_word(text))
    "c" => {
      let c = parse_hex_word(text)
      if c > 127U {
        raise Invalid("ASCII character required", 0)
      }
      Character(c.reinterpret_as_int())
    }
    "s" | "S" => {
      if text.length() > limits.string_bytes {
        raise Limit("JSON string bytes")
      }
      if !ascii_valid(text) {
        raise Invalid("ASCII string required", 0)
      }
      if tag == "s" {
        Text(text)
      } else {
        Symbol(text)
      }
    }
    "b" => Blob(hex_decode(text, max_bytes=limits.blob_bytes))
    _ => raise Invalid("unknown JSON type tag", 0)
  }
}

///|
fn packet_from_json(
  value : Json,
  depth : Int32,
  limits : Limits,
  budget : Budget,
) -> Packet raise OscError {
  if depth > limits.depth {
    raise Limit("JSON bundle depth")
  }
  budget.node(limits)
  let items = json_array(value)
  if items.length() != 3 {
    raise Invalid("JSON packet arity", 0)
  }
  let kind = json_string(items[0])
  let header = json_string(items[1])
  let children = json_array(items[2])
  match kind {
    "message" => {
      if header.length() > limits.string_bytes {
        raise Limit("JSON address bytes")
      }
      validate_address(header)
      if children.length() > limits.arguments - budget.args {
        raise Limit("JSON arguments")
      }
      Message({
        address: header,
        arguments: children.map(x => argument_from_json(x, 1, limits, budget)),
      })
    }
    "bundle" => {
      let t = TimeTag::from_bits(parse_hex_wide(header))
      if children.length() > limits.elements - budget.nodes {
        raise Limit("JSON packet nodes")
      }
      Bundle(
        t,
        children.map(x => packet_from_json(x, depth + 1, limits, budget)),
      )
    }
    _ => raise Invalid("unknown JSON packet kind", 0)
  }
}

///|
pub fn from_json(
  value : Json,
  limits~ : Limits = Limits::default(),
) -> Packet raise OscError {
  limits.validate()
  let root = json_array(value)
  if root.length() != 2 || json_string(root[0]) != "moonosc/1" {
    raise Invalid("JSON schema version", 0)
  }
  let packet = packet_from_json(root[1], 1, limits, Budget::{
    args: 0,
    nodes: 0,
  })
  ignore(encode(packet, limits~))
  packet
}

///|
/// Text parsing has both a byte/code-unit cap and parser nesting cap.
// Core 20260920 deprecates this safety bound without a replacement.
#warnings("-20")
pub fn parse_json(
  text : String,
  limits~ : Limits = Limits::default(),
) -> Packet raise OscError {
  limits.validate()
  if text.length() > limits.packet_bytes * 4 + 65536 {
    raise Limit("JSON text size")
  }
  let value = @json.parse(text[:], max_nesting_depth=limits.depth * 4 + 8) catch {
    _ => raise Invalid("malformed JSON text", 0)
  }
  from_json(value, limits~)
}
