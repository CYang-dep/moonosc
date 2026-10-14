///|
pub(all) struct Route {
  id : Int
  address : String
} derive(Eq, Debug)

///|
pub extend Route with Eq::{equal, not_equal}

///|
pub extend Route with @debug.Debug::{to_repr}

///|
pub struct Router {
  priv routes : Array[Route]
  priv capacity : Int
}

///|
pub fn Router::new(capacity? : Int = 256) -> Router raise OscError {
  if capacity < 1 || capacity > 4096 {
    raise Limit("route capacity must be 1..4096")
  }
  { routes: [], capacity, }
}

///|
pub fn Router::add(
  self : Router,
  id : Int,
  address : String,
) -> Unit raise OscError {
  validate_method(address)
  if address.length() > 4096 {
    raise Limit("method length")
  }
  if id < 0 {
    raise Invalid("route id must be nonnegative", 0)
  }
  for route in self.routes {
    if route.id == id || route.address == address {
      raise Invalid("duplicate route id or address", 0)
    }
  }
  if self.routes.length() >= self.capacity {
    raise Limit("route capacity")
  }
  self.routes.push({ id, address, })
}

///|
pub fn Router::remove(self : Router, id : Int) -> Bool {
  for i in 0..<self.routes.length() {
    if self.routes[i].id == id {
      ignore(self.routes.remove(i))
      return true
    }
  }
  false
}

///|
pub fn Router::snapshot(self : Router) -> Array[Route] {
  self.routes.copy()
}

///|
pub fn Router::len(self : Router) -> Int {
  self.routes.length()
}

///|
/// The message supplies the pattern; registered destinations are literal paths.
pub fn Router::resolve(
  self : Router,
  address : String,
  work_limit? : Int = 1000000,
) -> Array[Route] raise OscError {
  let pattern = compile_pattern(address)
  let work = Ref(0)
  let out : Array[Route] = []
  for route in self.routes {
    if pattern.match_budget(route.address, work_limit, work) {
      out.push(route)
    }
  }
  out
}
