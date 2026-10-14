///|
fn hex_digit(code : Int32) -> Int32? {
  if code >= 48 && code <= 57 {
    Some(code - 48)
  } else if code >= 65 && code <= 70 {
    Some(code - 55)
  } else if code >= 97 && code <= 102 {
    Some(code - 87)
  } else {
    None
  }
}

///|
pub fn hex_decode(
  text : String,
  max_bytes~ : Int32 = 1048576,
) -> Bytes raise OscError {
  if max_bytes < 0 || max_bytes > 16777216 {
    raise Limit("hex budget")
  }
  if text.length() % 2 != 0 {
    raise Invalid("odd hex length", text.length())
  }
  if text.length() / 2 > max_bytes {
    raise Limit("hex decoded bytes")
  }
  let out : Array[Byte] = []
  let mut i = 0
  while i < text.length() {
    let hi = match hex_digit(text[i].to_int()) {
      Some(n) => n
      None => raise Invalid("invalid hex digit", i)
    }
    let lo = match hex_digit(text[i + 1].to_int()) {
      Some(n) => n
      None => raise Invalid("invalid hex digit", i + 1)
    }
    out.push((hi * 16 + lo).to_byte())
    i += 2
  }
  Bytes::from_array(out)
}

///|
pub fn hex_encode(
  bytes : Bytes,
  max_bytes~ : Int32 = 1048576,
) -> String raise OscError {
  if max_bytes < 0 || max_bytes > 16777216 || bytes.length() > max_bytes {
    raise Limit("hex input bytes")
  }
  let out = StringBuilder()
  let digits = "0123456789abcdef"
  for b in bytes {
    out.write_char(digits[b.to_int() / 16].to_int().to_char().unwrap())
    out.write_char(digits[b.to_int() % 16].to_int().to_char().unwrap())
  }
  out.to_string()
}

///|
pub(all) struct PacketSummary {
  wire_bytes : Int32
  messages : Int32
  bundles : Int32
  arguments : Int32
  array_arguments : Int32
  blob_bytes : Int32
  max_depth : Int32
} derive(Eq, Debug)

///|
pub extend PacketSummary with Eq::{equal, not_equal}

///|
pub extend PacketSummary with @debug.Debug::{to_repr}

///|
priv struct SummaryBuilder {
  mut messages : Int32
  mut bundles : Int32
  mut arguments : Int32
  mut arrays : Int32
  mut blobs : Int32
  mut depth : Int32
}

///|
fn SummaryBuilder::argument(self : SummaryBuilder, arg : Argument) -> Unit {
  self.arguments += 1
  match arg {
    Array(items) => {
      self.arrays += 1
      for item in items {
        self.argument(item)
      }
    }
    Blob(bytes) => self.blobs += bytes.length()
    _ => ()
  }
}

///|
fn SummaryBuilder::packet(
  self : SummaryBuilder,
  packet : Packet,
  depth : Int32,
) -> Unit {
  if depth > self.depth {
    self.depth = depth
  }
  match packet {
    Message(m) => {
      self.messages += 1
      for a in m.arguments {
        self.argument(a)
      }
    }
    Bundle(_, children) => {
      self.bundles += 1
      for child in children {
        self.packet(child, depth + 1)
      }
    }
  }
}

///|
/// First validates all budgets; never inspect untrusted models recursively first.
pub fn summarize(
  packet : Packet,
  limits~ : Limits = Limits::default(),
) -> PacketSummary raise OscError {
  let wire = encode(packet, limits~)
  let owned = decode(wire, limits~)
  let builder = SummaryBuilder::{
    messages: 0,
    bundles: 0,
    arguments: 0,
    arrays: 0,
    blobs: 0,
    depth: 0,
  }
  builder.packet(owned, 1)
  {
    wire_bytes: wire.length(),
    messages: builder.messages,
    bundles: builder.bundles,
    arguments: builder.arguments,
    array_arguments: builder.arrays,
    blob_bytes: builder.blobs,
    max_depth: builder.depth,
  }
}
