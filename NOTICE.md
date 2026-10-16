# Attribution and reference boundaries

Copyright 2026 CYang-dep. Original MoonBit implementation, Apache-2.0.

Dependency: moonbitlang/core (Apache-2.0), delivered with the official toolchain.
The included LICENSE is the unmodified standard Apache-2.0 license text.
No vendor or upstream implementation source is incorporated.

Behavioral references:
- Open Sound Control 1.0: https://opensoundcontrol.stanford.edu/spec-1_0.html
- RFC 1055 SLIP: https://www.rfc-editor.org/rfc/rfc1055

Normative target for 0.2.0: OSC 1.0 dated 26 March 2002; see
 docs/osc-1.0-conformance.md for mandatory semantics, optional tags, permanent
 exclusions and host responsibilities. Optional tags are from OSC 1.0 itself.
 There is no OSC 1.1 or complete-server conformance claim. Protocol definitions inform independently written code
and tests. The Python reference encoder uses only struct and bytes, not an imported
OSC implementation. Adjacent sources were read for scope comparison only, not copied
or ported. See docs/competition/duplicate-check.md.
