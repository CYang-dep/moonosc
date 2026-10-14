///|
priv struct Budget {
  mut args : Int
  mut nodes : Int
}

///|
fn Budget::argument(self : Budget, limits : Limits) -> Unit raise OscError {
  if self.args >= limits.arguments {
    raise Limit("total arguments")
  }
  self.args += 1
}

///|
fn read_arguments(
  r : Reader,
  tags : String,
  cursor : Ref[Int],
  depth : Int,
  limits : Limits,
  budget : Budget,
  nested : Bool,
) -> Array[Argument] raise OscError {
  if depth > limits.depth {
    raise Limit("argument array depth")
  }
  let out : Array[Argument] = []
  while cursor.val < tags.length() {
    let tag = tags[cursor.val].to_int()
    cursor.val += 1
    if tag == 93 {
      if !nested {
        raise Invalid("unmatched array close", cursor.val - 1)
      }
      return out
    }
    budget.argument(limits)
    let arg = match tag {
      105 => I32(r.word().reinterpret_as_int())
      102 => F32(r.word())
      115 => Text(r.text(limits))
      98 => Blob(r.blob(limits))
      104 => I64(r.wide().reinterpret_as_int64())
      100 => F64(r.wide())
      116 => Time({ seconds: r.word(), fraction: r.word(), })
      83 => Symbol(r.text(limits))
      99 => {
        let c = r.word()
        if c > 127U {
          raise Invalid("non-ASCII character argument", r.pos - 4)
        }
        Character(c.reinterpret_as_int())
      }
      114 => Rgba(r.word())
      109 => Midi(r.word())
      84 => True
      70 => False
      78 => Nil
      73 => Impulse
      91 =>
        Array(read_arguments(r, tags, cursor, depth + 1, limits, budget, true))
      _ => raise Invalid("unsupported type tag", cursor.val - 1)
    }
    out.push(arg)
  }
  if nested {
    raise Invalid("unclosed argument array", cursor.val)
  }
  out
}

///|
fn collect_tags(
  args : Array[Argument],
  tags : Array[Char],
  depth : Int,
  limits : Limits,
  budget : Budget,
) -> Unit raise OscError {
  if depth > limits.depth {
    raise Limit("argument array depth")
  }
  for arg in args {
    budget.argument(limits)
    match arg {
      Array(values) => {
        tags.push('[')
        collect_tags(values, tags, depth + 1, limits, budget)
        tags.push(']')
      }
      _ => tags.push(argument_tag(arg))
    }
    if tags.length() > limits.string_bytes {
      raise Limit("type-tag bytes")
    }
  }
}

///|
fn write_arguments(w : Writer, args : Array[Argument]) -> Unit raise OscError {
  for arg in args {
    match arg {
      Array(values) => write_arguments(w, values)
      _ => write_argument(w, arg)
    }
  }
}
