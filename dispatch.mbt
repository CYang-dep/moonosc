///|
pub fn Message::type_tags(
  self : Message,
  limits? : Limits = Limits::default(),
) -> String raise OscError {
  limits.validate()
  let chars : Array[Char] = [',']
  collect_tags(self.arguments, chars, 1, limits, Budget::{ args: 0, nodes: 0, })
  String::from_array(chars[:])
}

///|
fn validate_signature(signature : String) -> Unit raise OscError {
  if signature.length() == 0 || signature[0] != 44 || signature.length() > 65536 {
    raise Invalid("signature must start with comma and fit bounds", 0)
  }
  let mut depth = 0
  for i in 1..<signature.length() {
    match signature[i].to_int() {
      91 => {
        depth += 1
        if depth > 64 {
          raise Limit("signature array depth")
        }
      }
      93 => {
        depth -= 1
        if depth < 0 {
          raise Invalid("signature unmatched close", i)
        }
      }
      105
      | 102
      | 115
      | 98
      | 104
      | 100
      | 116
      | 83
      | 99
      | 114
      | 109
      | 84
      | 70
      | 78
      | 73 => ()
      _ => raise Invalid("unsupported signature tag", i)
    }
  }
  if depth != 0 {
    raise Invalid("signature unclosed array", signature.length())
  }
}

///|
pub(all) struct Rejection {
  route : Route
  expected : String
  actual : String
} derive(Eq, Debug)

///|
pub extend Rejection with Eq::{equal, not_equal}

///|
pub extend Rejection with @debug.Debug::{to_repr}

///|
pub(all) struct DispatchPlan {
  accepted : Array[Route]
  rejected : Array[Rejection]
} derive(Eq, Debug)

///|
pub extend DispatchPlan with Eq::{equal, not_equal}

///|
pub extend DispatchPlan with @debug.Debug::{to_repr}

///|
priv struct Contract {
  id : Int
  signature : String?
}

///|
pub struct Dispatcher {
  priv router : Router
  priv contracts : Array[Contract]
}

///|
pub fn Dispatcher::new(capacity? : Int = 256) -> Dispatcher raise OscError {
  { router: Router::new(capacity~), contracts: [], }
}

///|
pub fn Dispatcher::add(
  self : Dispatcher,
  id : Int,
  address : String,
  signature? : String? = None,
) -> Unit raise OscError {
  if signature is Some(s) {
    validate_signature(s)
  }
  self.router.add(id, address)
  self.contracts.push({ id, signature, })
}

///|
pub fn Dispatcher::plan(
  self : Dispatcher,
  message : Message,
  all_or_nothing? : Bool = true,
  work_limit? : Int = 1000000,
  limits? : Limits = Limits::default(),
) -> DispatchPlan raise OscError {
  // Validate payloads as well as tag structure before admitting any destination.
  ignore(encode_message(message, limits~))
  let actual = message.type_tags(limits~)
  let routes = self.router.resolve(message.address, work_limit~)
  let accepted : Array[Route] = []
  let rejected : Array[Rejection] = []
  for route in routes {
    let mut expected : String? = None
    for contract in self.contracts {
      if contract.id == route.id {
        expected = contract.signature
        break
      }
    }
    match expected {
      Some(s) if s != actual => rejected.push({ route, expected: s, actual, })
      _ => accepted.push(route)
    }
  }
  if all_or_nothing && !rejected.is_empty() {
    accepted.clear()
  }
  { accepted, rejected, }
}
