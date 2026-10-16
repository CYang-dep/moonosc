# Architecture and invariants

The public model separates raw argument bits, messages and recursive packet trees.
Reader/Writer enforce network byte order, canonical padding and limits. A shared
Budget counts packet and argument nodes over the whole tree, not per branch.
Each bundle child receives a bounded reader endpoint; no child may consume a sibling.
Unknown tags, trailing bytes, negative lengths and nonzero padding are errors.

Pattern compilation yields literals, stars, single-character matches, ranges and
literal alternatives. Matching uses a rolling two-row dynamic program over method
positions, not recursive backtracking. Memory is O(method length); a shared operation
counter bounds atom-position/range/alternative comparisons, including router fanout.
Registration and contract lookup are deliberately bounded linear scans.

flatten validates by encode/decode before recursion, creating an owned snapshot.
Traversal is depth-first wire order; it is not a due-time sort. Immediate root time
resolves to supplied now; nested immediate time resolves to parent. Earlier explicit
child times are rejected. Enqueue checks entire flatten output, capacity and ticket
headroom before mutating the stable binary heap. Heap order is (due bits, ticket).
Cancellation scans tickets, then repairs in both directions. Poll transfers message
ownership out of the queue. discard_before implements an explicit exclusive cutoff.

Stream feeds work on candidate state and commit only on complete success. A failure
returns no output and preserves prior state even if the candidate contained valid
frames before a bad header/escape. Applications must retry a corrected chunk or reset;
blindly resending accepted chunks duplicates events. EOF requires empty pending state.
Transport frames do not themselves validate OSC payloads: call decode.

JSON encodes validated trees as versioned tagged arrays. All numeric fields are
fixed-width network-order hex; blob hex is bounded before allocation. Decode has
independent packet/argument budgets plus final canonical encode validation.
Text parsing caps input and parser nesting before visiting trees. JSON syntax itself
may be Unicode, but non-ASCII OSC fields are rejected.

No global clock, IO, callbacks, FFI, hidden caches or participant credentials are
part of the module. Scheduler/framer instances are mutable, single-owner objects.

## OSC 1.0 strict profile (0.2.0)

See [normative map](osc-1.0-conformance.md). encode_osc10/decode_osc10 validate all
wire budgets, address syntax, core-only tags and raw parent/child time ordering.
plan_osc10 snapshots through bounded encoding/decoding before traversal. Each bundle's
direct messages are collected in wire order into one batch; nested bundles form
separate batches. Empty bundles emit none. Parent direct batch precedes nested
batches in planning order; the scheduler chooses due bits then ticket across groups.

Osc10Scheduler uses a bounded array, NOT the generic Scheduler heap. Admission is
transactional across all planned batches. Earliest selection/cancellation is O(n);
polling k batches is O(k*n) including array removal. This favors explicit,
reviewable atomic boundaries, not a throughput claim. Capacity is in batches; the
host executes each transferred batch without unrelated processing. The old flatten /
Scheduler remain compatibility per-message APIs and cannot supply this guarantee.
