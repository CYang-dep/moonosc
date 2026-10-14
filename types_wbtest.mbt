///|
test "address and method boundaries" {
  validate_address("/synth/*")
  validate_method("/synth/gain")
  for a in ["", "gain", "/a b", "/é", "/#"] {
    assert_true(
      try {
        validate_address(a)
        false
      } catch {
        _ => true
      },
    )
  }
  for a in ["/", "/a/", "/a//b", "/a*"] {
    assert_true(
      try {
        validate_method(a)
        false
      } catch {
        _ => true
      },
    )
  }
  Limits::default().validate()
}

///|
test "floating arguments retain bit identity" {
  assert_eq(float_argument(-0.0F), F32(0x80000000U))
  assert_eq(double_argument(-0.0), F64(0x8000000000000000UL))
}
