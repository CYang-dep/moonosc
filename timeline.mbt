///|
pub(all) struct TimedMessage {
  due : TimeTag
  message : Message
  order : Int
} derive(Eq, Debug)

///|
pub extend TimedMessage with Eq::{equal, not_equal}

///|
pub extend TimedMessage with @debug.Debug::{to_repr}

///|
fn flatten_packet(
  packet : Packet,
  inherited : TimeTag,
  parent : TimeTag?,
  out : Array[TimedMessage],
) -> Unit raise OscError {
  match packet {
    Message(message) =>
      out.push({ due: inherited, message, order: out.length(), })
    Bundle(time, children) => {
      // Immediate nested bundles execute at their enclosing bundle's time.
      let due = if time.is_immediate() { inherited } else { time }
      if parent is Some(p) && due.bits() < p.bits() {
        raise Invalid("nested bundle precedes enclosing bundle", out.length())
      }
      for child in children {
        flatten_packet(child, due, Some(due), out)
      }
    }
  }
}

///|
/// Returns owned message trees in depth-first wire order, not sorted due order.
pub fn flatten(
  packet : Packet,
  now : TimeTag,
  limits? : Limits = Limits::default(),
) -> Array[TimedMessage] raise OscError {
  if now.is_immediate() {
    raise Invalid("now must be absolute", 0)
  }
  let owned = decode(encode(packet, limits~), limits~)
  let out : Array[TimedMessage] = []
  flatten_packet(owned, now, None, out)
  out
}
