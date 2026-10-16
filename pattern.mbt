///|
priv enum PatternAtom {
  Literal(Int32)
  Any
  Star
  Class(Bool, Array[(Int32, Int32)])
  Choices(Array[String])
}

///|
pub struct Pattern {
  priv atoms : Array[PatternAtom]
  priv source_ : String
}

///|
pub fn Pattern::source(self : Pattern) -> String {
  self.source_
}

///|
fn parse_class(
  text : String,
  cursor : Ref[Int32],
) -> PatternAtom raise OscError {
  let start = cursor.val
  cursor.val += 1
  let negated = cursor.val < text.length() && text[cursor.val] == 33
  if negated {
    cursor.val += 1
  }
  let ranges : Array[(Int32, Int32)] = []
  while cursor.val < text.length() && text[cursor.val] != 93 {
    let lo = text[cursor.val].to_int()
    cursor.val += 1
    if lo == 47 {
      raise Invalid("illegal class character", cursor.val - 1)
    }
    let mut hi = lo
    if cursor.val + 1 < text.length() &&
      text[cursor.val] == 45 &&
      text[cursor.val + 1] != 93 {
      hi = text[cursor.val + 1].to_int()
      cursor.val += 2
      if hi < lo || hi == 47 {
        raise Invalid("invalid class range", cursor.val - 2)
      }
    }
    ranges.push((lo, hi))
  }
  if cursor.val >= text.length() || ranges.is_empty() {
    raise Invalid("unclosed or empty class", start)
  }
  cursor.val += 1
  Class(negated, ranges)
}

///|
fn parse_choices(
  text : String,
  cursor : Ref[Int32],
) -> PatternAtom raise OscError {
  let start = cursor.val
  cursor.val += 1
  let choices : Array[String] = []
  let word : Array[Char] = []
  while cursor.val < text.length() {
    let c = text[cursor.val].to_int()
    cursor.val += 1
    if c == 44 || c == 125 {
      choices.push(String::from_array(word[:]))
      word.clear()
      if c == 125 {
        return Choices(choices)
      }
    } else {
      match c {
        47 | 123 =>
          raise Invalid(
            "brace alternatives cannot cross segments or nest",
            cursor.val - 1,
          )
        _ => word.push(c.to_char().unwrap())
      }
    }
  }
  raise Invalid("unclosed brace alternatives", start)
}

///|
pub fn compile_pattern(text : String) -> Pattern raise OscError {
  validate_address(text)
  if text.length() > 4096 {
    raise Limit("address pattern length")
  }
  let atoms : Array[PatternAtom] = []
  let cursor = Ref(0)
  while cursor.val < text.length() {
    let c = text[cursor.val].to_int()
    match c {
      91 => atoms.push(parse_class(text, cursor))
      123 => atoms.push(parse_choices(text, cursor))
      93 | 125 | 44 => raise Invalid("unmatched pattern delimiter", cursor.val)
      _ => {
        cursor.val += 1
        if c == 42 {
          // Consecutive stars have the same language and need only one state.
          match atoms.last() {
            Some(Star) => ()
            _ => atoms.push(Star)
          }
        } else if c == 63 {
          atoms.push(Any)
        } else {
          atoms.push(Literal(c))
        }
      }
    }
  }
  { atoms, source_: text, }
}
