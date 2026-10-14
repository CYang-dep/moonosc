///|
test "OSC matching uses incoming pattern against concrete method" {
  for
    (p, m) in [
      ("/a/*", "/a/left"),
      ("/a/?", "/a/x"),
      ("/a/[a-z]", "/a/k"),
      ("/a/[!0-9]", "/a/x"),
      ("/a/{left,right}", "/a/right"),
      ("/a/*b*c", "/a/bbbc"),
    ] {
    assert_true(@moonosc.matches(p, m))
  }
  for
    (p, m) in [
      ("/a/*", "/a/x/y"),
      ("/a/?", "/a/xy"),
      ("/a/[!0-9]", "/a/7"),
      ("/a/{left,right}", "/a/le"),
      ("/a/*b*c", "/a/b"),
    ] {
    assert_false(@moonosc.matches(p, m))
  }
}

///|
test "adversarial stars are bounded not recursive" {
  let p = @moonosc.compile_pattern("/a/*a*a*a*a*a*a*a*a*b")
  assert_false(p.matches("/a/aaaaaaaaaaaaa"))
  assert_true(
    try {
      ignore(p.matches("/a/aaaaaaaaaaaaa", work_limit=2))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "wildcard DP agrees with explicit finite alternatives" {
  for a in ["a", "b", "aa", "ab", "ba", "bb"] {
    assert_eq(@moonosc.matches("/x/a*", "/x/" + a), a.has_prefix("a"))
    assert_eq(@moonosc.matches("/x/?", "/x/" + a), a.length() == 1)
    assert_eq(@moonosc.matches("/x/{a,b}", "/x/" + a), a == "a" || a == "b")
  }
}
