# Attribution and reference boundaries

Copyright 2026 CYang-dep. Original MoonBit implementation, Apache-2.0.

Dependency: moonbitlang/core (Apache-2.0), delivered with the official toolchain.
The included LICENSE is the unmodified standard Apache-2.0 license text.
No vendor or upstream implementation source is incorporated.

Behavioral references:
- Open Sound Control 1.0: https://opensoundcontrol.stanford.edu/spec-1_0.html
- OSC 1.1 page (limited available content): https://opensoundcontrol.stanford.edu/spec-1_1.html
- RFC 1055 SLIP: https://www.rfc-editor.org/rfc/rfc1055

Extended type tags and ASCII-only limits are explicit; this is not an exhaustive
OSC 1.1 conformance claim. Protocol definitions inform independently written code
and tests. The Python reference encoder uses only struct and bytes, not an imported
OSC implementation. Adjacent sources were read for scope comparison only, not copied
or ported. See docs/competition/duplicate-check.md.
