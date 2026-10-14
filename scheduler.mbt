///|
pub(all) struct Scheduled {
  ticket : UInt64
  due : TimeTag
  message : Message
} derive(Eq, Debug)

///|
pub extend Scheduled with Eq::{equal, not_equal}

///|
pub extend Scheduled with @debug.Debug::{to_repr}

///|
pub struct Scheduler {
  priv heap : Array[Scheduled]
  priv capacity : Int
  priv mut next_ticket : UInt64
}

///|
pub fn Scheduler::new(capacity? : Int = 4096) -> Scheduler raise OscError {
  if capacity < 1 || capacity > 65536 {
    raise Limit("queue capacity must be 1..65536")
  }
  { heap: [], capacity, next_ticket: 1UL, }
}

///|
fn earlier(a : Scheduled, b : Scheduled) -> Bool {
  a.due.bits() < b.due.bits() || (a.due == b.due && a.ticket < b.ticket)
}

///|
fn Scheduler::insert(self : Scheduler, event : Scheduled) -> Unit {
  self.heap.push(event)
  let mut i = self.heap.length() - 1
  while i > 0 {
    let p = (i - 1) / 2
    if !earlier(self.heap[i], self.heap[p]) {
      break
    }
    self.heap.swap(i, p)
    i = p
  }
}

///|
fn Scheduler::sift_down(self : Scheduler, start : Int) -> Unit {
  let mut i = start
  while i < self.heap.length() / 2 {
    let left = 2 * i + 1
    let right = left + 1
    let best = if right < self.heap.length() &&
      earlier(self.heap[right], self.heap[left]) {
      right
    } else {
      left
    }
    if !earlier(self.heap[best], self.heap[i]) {
      break
    }
    self.heap.swap(i, best)
    i = best
  }
}

///|
fn Scheduler::take(self : Scheduler) -> Scheduled {
  let first = self.heap[0]
  let last = self.heap.pop().unwrap()
  if !self.heap.is_empty() {
    self.heap[0] = last
    self.sift_down(0)
  }
  first
}

///|
/// Admission is transactional: flatten and all capacities checked before mutation.
pub fn Scheduler::enqueue(
  self : Scheduler,
  packet : Packet,
  now : TimeTag,
  limits? : Limits = Limits::default(),
) -> Array[UInt64] raise OscError {
  let events = flatten(packet, now, limits~)
  if events.length() > self.capacity - self.heap.length() {
    raise Limit("queue capacity")
  }
  if events.length().to_uint64() > 0xffffffffffffffffUL - self.next_ticket {
    raise Limit("ticket counter exhausted")
  }
  let ids : Array[UInt64] = []
  for event in events {
    let ticket = self.next_ticket
    self.next_ticket += 1UL
    self.insert({ ticket, due: event.due, message: event.message, })
    ids.push(ticket)
  }
  ids
}

///|
pub fn Scheduler::poll(
  self : Scheduler,
  now : TimeTag,
  max_count? : Int = 4096,
) -> Array[Scheduled] raise OscError {
  if now.is_immediate() {
    raise Invalid("poll requires absolute now", 0)
  }
  if max_count < 0 || max_count > 65536 {
    raise Limit("poll count must be 0..65536")
  }
  let out : Array[Scheduled] = []
  while !self.heap.is_empty() && out.length() < max_count {
    if self.heap[0].due.bits() > now.bits() {
      break
    }
    out.push(self.take())
  }
  out
}

///|
pub fn Scheduler::len(self : Scheduler) -> Int {
  self.heap.length()
}

///|
pub fn Scheduler::next_due(self : Scheduler) -> TimeTag? {
  if self.heap.is_empty() {
    None
  } else {
    Some(self.heap[0].due)
  }
}

///|
/// Cancel one ticket. Removing a non-root node restores the heap in both directions.
pub fn Scheduler::cancel(self : Scheduler, ticket : UInt64) -> Bool {
  let mut index = -1
  for i in 0..<self.heap.length() {
    if self.heap[i].ticket == ticket {
      index = i
      break
    }
  }
  if index < 0 {
    return false
  }
  let last = self.heap.pop().unwrap()
  if index < self.heap.length() {
    self.heap[index] = last
    let mut i = index
    while i > 0 {
      let parent = (i - 1) / 2
      if !earlier(self.heap[i], self.heap[parent]) {
        break
      }
      self.heap.swap(i, parent)
      i = parent
    }
    self.sift_down(i)
  }
  true
}

///|
/// Explicit late-event policy: discard events strictly before cutoff, returning them
/// in stable order. Equality is retained. Validation happens before any mutation.
pub fn Scheduler::discard_before(
  self : Scheduler,
  cutoff : TimeTag,
) -> Array[Scheduled] raise OscError {
  if cutoff.is_immediate() {
    raise Invalid("cutoff requires absolute time", 0)
  }
  let out : Array[Scheduled] = []
  while !self.heap.is_empty() && self.heap[0].due.bits() < cutoff.bits() {
    out.push(self.take())
  }
  out
}

///|
/// Clear pending messages without recycling ticket identities.
pub fn Scheduler::clear(self : Scheduler) -> Int {
  let count = self.heap.length()
  self.heap.clear()
  count
}
