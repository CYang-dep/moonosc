# Security and unsupported behavior

All input is untrusted. Default Limits: 1 MiB packet, 64 KiB string, 512 KiB blob,
4096 arguments, 4096 total packet nodes and depth 32. Maximum configurable packet is
16 MiB and depth 64. Limits count container nodes too. Stream budgets additionally
limit feed size (default 16 MiB), maximum frame and output frames (4096). Large feeds
may hold candidate input and output copies at once; bounded does not mean allocation-free.

Pattern source and method are at most 4096 code units; default work budget is 1,000,000,
maximum 16,777,216. Fanout exceeding the shared budget fails, not a partial result.
Scheduler capacity defaults to 4096, maximum 65536. Ticket overflow fails before
admission. There is no ticket reuse across clear.

Binary error offsets are within the provided packet; JSON semantic errors currently
use offset zero, not JSON paths. Framer offsets are local to the failed feed/candidate.
This library is not authentication, rate limiting, transport integrity, or command
authorization. Exposed methods should be allowlisted and isolated by the host.
Mutable argument arrays must not be concurrently changed during calls. Queued
packets are snapshot-owned.

NTP era zero is explicit: callers must resolve the 2036 rollover themselves. No clock
synchronization or hard-realtime guarantee. Bundles encode protocol data only;
scheduling validation is stricter about nested timing. Poll/late cutoff require
absolute times. Under load applications choose explicit drop policies.

Only ASCII OSC strings/characters, listed tags and literal brace alternatives are
supported. Strict zero-padding may reject noncanonical senders. Unknown tags are not
silently skipped. No recursive descendant wildcard, sockets or Unicode extensions.

Core 20260920 marks the JSON parser nesting-bound parameter deprecated without a
replacement; the single parse_json call locally suppresses that deprecation to keep
the safety cap. No broad warnings are suppressed. CI exercises this supported call.
