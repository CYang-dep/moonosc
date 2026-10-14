///|
test "typed dispatch supports all_or_nothing and partial admission" {
  let d = @moonosc.Dispatcher::new()
  d.add(1, "/synth/a", signature=Some(",f"))
  d.add(2, "/synth/b", signature=Some(",i"))
  let m = @moonosc.Message::{
    address: "/synth/*",
    arguments: [@moonosc.I32(4)],
  }
  let p = d.plan(m)
  assert_eq(p.accepted.length(), 0)
  assert_eq(p.rejected[0].route.id, 1)
  assert_eq(d.plan(m, all_or_nothing=false).accepted.map(r => r.id), [2])
}

///|
test "dispatch signatures reject syntax before adding route" {
  let d = @moonosc.Dispatcher::new(capacity=1)
  assert_true(
    try {
      d.add(1, "/x", signature=Some(",[i"))
      false
    } catch {
      _ => true
    },
  )
  d.add(1, "/x", signature=Some(",[i]"))
  let m = @moonosc.Message::{
    address: "/x",
    arguments: [@moonosc.Array([@moonosc.I32(1)])],
  }
  assert_eq(d.plan(m).accepted.length(), 1)
}
