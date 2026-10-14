# moonosc/1 JSON representation

The top level is ["moonosc/1", packet]. A message is ["message", address, arguments].
A bundle is ["bundle", timetagHex16, children]. All arrays have exact arity.
Arguments are [tag, value], except T/F/N/I are one-element [tag] arrays.
An array argument is ["[", arguments]. OSC i/f/c/r/m use eight hex digits;
h/d/t use sixteen. Signed integer two's-complement and IEEE payload bits are not
converted to decimals. s/S use ASCII strings; b uses an even-length hex string.
Uppercase hex is accepted; output uses lowercase. Extra values, unknown version/tags,
JSON numeric payloads and malformed widths are rejected. This is a MoonOSC diagnostic
schema, not an OSC standard or generic JSON-RPC schema.

Example: ["moonosc/1", ["message", "/gain", [["f", "3f000000"]]]]
