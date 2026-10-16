# Changelog

## 0.2.0 — 2026-10-16

- Fix the normative target to OSC 1.0 (26 March 2002), with a Chinese requirement/API/test map and three executable cases.
- Add strict core-only encode/decode/planning; reject malformed patterns and child timetags before parent before admission.
- Add owned, transactional Osc10Scheduler batches preserving direct-message atomic groups across nested bundles; max_batches cannot split a group.
- Complete literal brace alternatives, including empty alternatives; charge work for every alternative and validate work limits even on an empty router.
- Preserve generic codecs, per-message queue and nested-immediate convenience behavior without mislabeling their guarantees.
- Add 11 profile tests (55 total), a 96-batch independent queue model, a fourth integration, and four-target CI execution.
- Explicitly separate required semantics, OSC 1.0 optional tags, permanent exclusions, resource limits and host execution obligations.

## 0.1.0 — 2026-10-14

- Typed OSC message/bundle codecs with bounded aggregate budgets.
- Extended scalar and array tags preserving raw IEEE/integer/timetag bits.
- Compiled segment patterns, bounded DP fanout and inert signature dispatch.
- Explicit NTP-era-zero helpers, nested timing flattening and cancellable stable queue.
- Transactional size-prefix/SLIP stream feeds, EOF validation and reset.
- Hex diagnostics, packet summaries and versioned lossless JSON bridge.
- Three runnable integrations, independent wire oracle and cross-target CI.
