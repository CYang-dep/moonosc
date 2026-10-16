///|
test "compile supported OSC pattern grammar" {
  for text in ["/synth/*", "/a/?", "/a/[a-z]", "/a/[!0-9]", "/a/{left,right}"] {
    assert_eq(@moonosc.compile_pattern(text).source(), text)
  }
}

///|
test "reject malformed and unsupported pattern constructs" {
  for text in ["/a/[", "/a/[]", "/a/[z-a]", "/a/{x", "/a/}", "/a/{x/y}"] {
    assert_true(
      try {
        ignore(@moonosc.compile_pattern(text))
        false
      } catch {
        _ => true
      },
    )
  }
}
