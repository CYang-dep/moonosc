///|
/// The normative baseline is OSC 1.0 (26 March 2002), core tags i/f/s/b.
/// The generic codec remains the opt-in path for the optional tag table.
fn validate_osc10_tree(
  packet : Packet,
  parent : TimeTag?,
) -> Unit raise OscError {
  match packet {
    Message(message) => {
      if message.address.contains("//") {
        raise Invalid("OSC 1.0 profile excludes recursive descendant //", 0)
      }
      ignore(compile_pattern(message.address))
      for argument in message.arguments {
        match argument {
          I32(_) | F32(_) | Text(_) | Blob(_) => ()
          _ => raise Invalid("OSC 1.0 core entry requires only i/f/s/b tags", 0)
        }
      }
    }
    Bundle(time, children) => {
      // Strict comparison of on-wire timetags: no implicit child-time repair.
      if parent is Some(p) && time.bits() < p.bits() {
        raise Invalid("OSC 1.0 child timetag precedes parent", 0)
      }
      for child in children {
        validate_osc10_tree(child, Some(time))
      }
    }
  }
}

///|
pub fn decode_osc10(
  bytes : Bytes,
  limits~ : Limits = Limits::default(),
) -> Packet raise OscError {
  let packet = decode(bytes, limits~)
  validate_osc10_tree(packet, None)
  packet
}

///|
pub fn encode_osc10(
  packet : Packet,
  limits~ : Limits = Limits::default(),
) -> Bytes raise OscError {
  // Bound and snapshot user-owned trees before recursively checking the profile.
  let wire = encode(packet, limits~)
  validate_osc10_tree(decode(wire, limits~), None)
  wire
}

///|
pub(all) struct Osc10Batch {
  due : TimeTag
  messages : Array[Message]
} derive(Eq, Debug)

///|
pub extend Osc10Batch with Eq::{equal, not_equal}

///|
pub extend Osc10Batch with @debug.Debug::{to_repr}

///|
fn collect_osc10_batches(
  packet : Packet,
  inherited : TimeTag,
  out : Array[Osc10Batch],
) -> Unit {
  match packet {
    Message(message) => out.push({ due: inherited, messages: [message], })
    Bundle(time, children) => {
      let due = if time.is_immediate() { inherited } else { time }
      let direct : Array[Message] = []
      for child in children {
        if child is Message(message) {
          direct.push(message)
        }
      }
      // Nested bundles are separate atomic groups, not DFS interleaving points.
      if !direct.is_empty() {
        out.push({ due, messages: direct, })
      }
      for child in children {
        if child is Bundle(_, _) {
          collect_osc10_batches(child, due, out)
        }
      }
    }
  }
}

///|
/// Owns data and preserves each bundle's direct-message atomic group.
/// Hosts must run an entire returned group without unrelated callback processing.
pub fn plan_osc10(
  packet : Packet,
  now : TimeTag,
  limits~ : Limits = Limits::default(),
) -> Array[Osc10Batch] raise OscError {
  if now.is_immediate() {
    raise Invalid("OSC 1.0 planning requires absolute now", 0)
  }
  let owned = decode_osc10(encode(packet, limits~), limits~)
  let out : Array[Osc10Batch] = []
  collect_osc10_batches(owned, now, out)
  out
}
