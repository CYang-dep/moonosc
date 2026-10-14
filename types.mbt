///|
pub suberror OscError {
  Invalid(String, Int32)
  Limit(String)
} derive(Debug, Eq)

///|
pub(all) struct TimeTag {
  seconds : UInt32
  fraction : UInt32
} derive(Debug, Eq)

///|
pub(all) enum Argument {
  I32(Int32)
  F32(UInt32)
  Text(String)
  Blob(Bytes)
  I64(Int64)
  F64(UInt64)
  Time(TimeTag)
  Symbol(String)
  Character(Int32)
  Rgba(UInt32)
  Midi(UInt32)
  True
  False
  Nil
  Impulse
  Array(Array[Argument])
} derive(Debug, Eq)

///|
pub(all) struct Message {
  address : String
  arguments : Array[Argument]
} derive(Debug, Eq)

///|
pub(all) enum Packet {
  Message(Message)
  Bundle(TimeTag, Array[Packet])
} derive(Debug, Eq)

///|
pub(all) struct Limits {
  packet_bytes : Int32
  string_bytes : Int32
  blob_bytes : Int32
  arguments : Int32
  elements : Int32
  depth : Int32
} derive(Debug, Eq)

///|
pub fn Limits::default() -> Limits {
  {
    packet_bytes: 1048576,
    string_bytes: 65536,
    blob_bytes: 524288,
    arguments: 4096,
    elements: 4096,
    depth: 32,
  }
}

///|
fn Limits::validate(self : Limits) -> Unit raise OscError {
  if self.packet_bytes < 16 || self.packet_bytes > 16777216 {
    raise Limit("packet_bytes must be 16..16777216")
  }
  if self.string_bytes < 1 || self.string_bytes > self.packet_bytes {
    raise Limit("string_bytes must fit packet budget")
  }
  if self.blob_bytes < 0 || self.blob_bytes > self.packet_bytes {
    raise Limit("blob_bytes must fit packet budget")
  }
  if self.arguments < 0 ||
    self.arguments > 65536 ||
    self.elements < 0 ||
    self.elements > 65536 {
    raise Limit("counts must be 0..65536")
  }
  if self.depth < 1 || self.depth > 64 {
    raise Limit("depth must be 1..64")
  }
}

///|
pub fn float_argument(value : Float) -> Argument {
  F32(value.reinterpret_as_uint())
}

///|
pub fn double_argument(value : Double) -> Argument {
  F64(value.reinterpret_as_uint64())
}

///|
fn ascii_valid(text : String) -> Bool {
  for code in text.code_units() {
    if code == 0 || code > 127 {
      return false
    }
  }
  true
}

///|
pub fn validate_address(address : String) -> Unit raise OscError {
  if address.length() == 0 || address[0] != 47 || !ascii_valid(address) {
    raise Invalid("address must be non-NUL ASCII starting with /", 0)
  }
  for i in 0..<address.length() {
    if address[i] < 33 || address[i] == 127 || address[i] == 35 {
      raise Invalid("illegal address character", i)
    }
  }
}

///|
pub fn validate_method(address : String) -> Unit raise OscError {
  validate_address(address)
  if address == "/" || address.has_suffix("/") || address.contains("//") {
    raise Invalid("method requires nonempty path segments", 0)
  }
  for i in 0..<address.length() {
    match address[i].to_int() {
      42 | 63 | 91 | 93 | 123 | 125 | 44 =>
        raise Invalid("pattern metacharacter in concrete method", i)
      _ => ()
    }
  }
}

///|
pub extend OscError with Eq::{equal, not_equal}

///|
pub extend OscError with @debug.Debug::{to_repr}

///|
pub extend TimeTag with Eq::{equal, not_equal}

///|
pub extend TimeTag with @debug.Debug::{to_repr}

///|
pub extend Argument with Eq::{equal, not_equal}

///|
pub extend Argument with @debug.Debug::{to_repr}

///|
pub extend Message with Eq::{equal, not_equal}

///|
pub extend Message with @debug.Debug::{to_repr}

///|
pub extend Packet with Eq::{equal, not_equal}

///|
pub extend Packet with @debug.Debug::{to_repr}

///|
pub extend Limits with Eq::{equal, not_equal}

///|
pub extend Limits with @debug.Debug::{to_repr}
