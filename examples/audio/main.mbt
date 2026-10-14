///|
fn main {
  try {
    let dispatch = @osc.Dispatcher::new()
    dispatch.add(1, "/mixer/left/gain", signature=Some(",f"))
    dispatch.add(2, "/mixer/right/gain", signature=Some(",f"))
    let request = @osc.Message::{
      address: "/mixer/{left,right}/gain",
      arguments: [@osc.float_argument(0.5)],
    }
    let raw = @osc.encode_message(request)
    let plan = dispatch.plan(@osc.decode_message(raw))
    assert_eq(plan.accepted.map(x => x.id), [1, 2])
    assert_eq(plan.rejected.length(), 0)
    println("audio: typed gain request accepted by 2 destinations")
  } catch {
    _ => abort("audio workflow failed")
  }
}
