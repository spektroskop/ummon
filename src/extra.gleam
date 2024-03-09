pub fn return(a: fn(a) -> b, body: fn() -> a) -> b {
  a(body())
}
