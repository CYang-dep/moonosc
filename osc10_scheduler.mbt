///|
pub(all) struct ScheduledOsc10Batch {
  ticket : UInt64
  due : TimeTag
  messages : Array[Message]
} derive(Eq, Debug)

///|
pub extend ScheduledOsc10Batch with Eq::{equal, not_equal}

///|
pub extend ScheduledOsc10Batch with @debug.Debug::{to_repr}

///|
pub struct Osc10Scheduler {
  priv pending : Array[ScheduledOsc10Batch]
  priv capacity : Int32
  priv mut next_ticket : UInt64
}

///|
pub fn Osc10Scheduler::new(
  capacity~ : Int32 = 4096,
) -> Osc10Scheduler raise OscError {
  if capacity < 1 || capacity > 65536 {
    raise Limit("batch capacity must be 1..65536")
  }
  { pending: [], capacity, next_ticket: 1UL, }
}

///|
/// Transactional admission; capacity counts indivisible batches, not messages.
pub fn Osc10Scheduler::enqueue(
  self : Osc10Scheduler,
  packet : Packet,
  now : TimeTag,
  limits~ : Limits = Limits::default(),
) -> Array[UInt64] raise OscError {
  let batches = plan_osc10(packet, now, limits~)
  if batches.length() > self.capacity - self.pending.length() {
    raise Limit("batch capacity")
  }
  if batches.length().to_uint64() > 0xffffffffffffffffUL - self.next_ticket {
    raise Limit("batch ticket counter exhausted")
  }
  let tickets : Array[UInt64] = []
  for batch in batches {
    let ticket = self.next_ticket
    self.next_ticket += 1UL
    self.pending.push({ ticket, due: batch.due, messages: batch.messages, })
    tickets.push(ticket)
  }
  tickets
}

///|
fn Osc10Scheduler::earliest_index(self : Osc10Scheduler) -> Int32 {
  let mut best = 0
  for i in 1..<self.pending.length() {
    let a = self.pending[i]
    let b = self.pending[best]
    if a.due.bits() < b.due.bits() || (a.due == b.due && a.ticket < b.ticket) {
      best = i
    }
  }
  best
}

///|
/// max_batches never splits a batch, even when it contains many messages.
pub fn Osc10Scheduler::poll(
  self : Osc10Scheduler,
  now : TimeTag,
  max_batches~ : Int32 = 4096,
) -> Array[ScheduledOsc10Batch] raise OscError {
  if now.is_immediate() {
    raise Invalid("batch poll requires absolute now", 0)
  }
  if max_batches < 0 || max_batches > 65536 {
    raise Limit("poll batch count must be 0..65536")
  }
  let out : Array[ScheduledOsc10Batch] = []
  while !self.pending.is_empty() && out.length() < max_batches {
    let best = self.earliest_index()
    if self.pending[best].due.bits() > now.bits() {
      break
    }
    out.push(self.pending.remove(best))
  }
  out
}

///|
pub fn Osc10Scheduler::len(self : Osc10Scheduler) -> Int32 {
  self.pending.length()
}

///|
pub fn Osc10Scheduler::next_due(self : Osc10Scheduler) -> TimeTag? {
  if self.pending.is_empty() {
    None
  } else {
    Some(self.pending[self.earliest_index()].due)
  }
}

///|
pub fn Osc10Scheduler::cancel(self : Osc10Scheduler, ticket : UInt64) -> Bool {
  for i in 0..<self.pending.length() {
    if self.pending[i].ticket == ticket {
      ignore(self.pending.remove(i))
      return true
    }
  }
  false
}

///|
pub fn Osc10Scheduler::clear(self : Osc10Scheduler) -> Int32 {
  let count = self.pending.length()
  self.pending.clear()
  count
}
