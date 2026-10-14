# Bounded semantic duplication review — 2026-10-14

## Process and decision

The installed osc2026-guide Project Research Guide was actually followed, using
the hackathon-builder fixed September competition requirements (participant deadline
2026-10-30). It informed ecosystem research, not a uniqueness verdict. The permanent
local registry was read by semantic fingerprint, and MoonOSC was atomically reserved
before implementation. Repository and publication authorization are project-specific.

Three candidates were evaluated. Scores below are decision judgments on a 0..5 scale,
not measured quality claims; a mature direct substitute is a veto regardless of sum.

| Candidate | Three-workflow reuse | Ecosystem need | Independence | Feasible delivery | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| RDF graph exchange/parsing | 5 | 2 | 0 | 4 | Reject: mature Turtle/TriG and adjacent SHACL |
| Outward-rounded numeric interval arithmetic | 5 | 2 | 0 | 4 | Reject: mature BallFloat/certified rounding |
| Open Sound Control processing | 5 | 4 | 5 | 4 | Select, bounded review found no maintained direct MoonBit replacement |

MoonOSC serves audio parameter-method dispatch, interactive-media timed cue scheduling,
and device stream validation/diagnostic replay. The shared typed packet model supports
all three. This is not a single-format converter or audio oscillator implementation.

## Search coverage and limits

MoonCakes searches used limit 100: osc, sound, control, bundle, timetag, rdf, turtle,
sparql, interval, numeric, rounding, Open Sound Control, OSC-message, OSC-pattern,
NTP-timetag, SLIP, liblo, oscpack and 跨媒体控制. The numeric result reached the limit,
so that broad result is truncated. Narrow sound-control queries had no relevant
protocol implementation. Fuzzy hits are not exact matches and were inspected as such.
The public docs pages and locally downloaded package sources/interfaces/tests were
examined, not merely search titles. No full registry-wide source census is claimed.

GitHub repository queries: Open Sound Control + language:MoonBit (0), osc + language
(4 unrelated), RDF (moonshacl) and interval arithmetic (0 despite a real MoonCakes
BallFloat implementation). Code queries: timetag, #bundle, Open Sound Control and
oscpack returned no matches. General OSC returned 936 hits; only the first 100 were
inspected. Many mean terminal escape OSC or oscillator, not Open Sound Control.
GitHub indexes are incomplete and cannot prove absence.

Official list: https://github.com/moonbitlang/awesome-moonbit (actual README reviewed,
including networking/async, regex and protocol/codegen categories). No OSC library was
listed there. An initial moonbit-community/awesome-moonbit path was 404; this failure
was corrected, not counted as evidence. Competition-oriented keywords return unrelated
OSC-2026 entries; these cannot alone establish protocol overlap.

Final reverse checks on 2026-10-14: GitHub code searches for SizeFramer, Open Sound
Control and SLIP+timetag in MoonBit returned empty lists. MoonCakes narrow Open Sound
Control returned two unrelated fuzzy hits; OSC-pattern one pathfinding hit;
NTP-timetag none; SLIP three unrelated geography/fluid/slippage matches. These checks
repeat central behavior/interface terms, not just the project name. This report's
conclusion is limited to visible indexed results and inspected sources on this date.

## Source-level capability comparison

| Inspected project/version | Concrete evidence inspected | Actual central capability | Classification |
| --- | --- | --- | --- |
| thy1016/moonttl 0.3.0 | generated interface, gen_trig implementation/materialization tests, MoonCakes detail | Turtle/TriG RDF graph IO/materialization | Mature direct replacement for rejected RDF candidate |
| Luna-Flow/floating 0.10.0 | BallFloat interface/implementation, certified_rounding tests, detail | Floating enclosures and certified rounding | Mature direct replacement for rejected interval candidate |
| dongxuan2012/oscbridge 0.2.0 | types/API/events implementation and tests, package detail | COMTRADE electric-power waveform recording, Arrow/event windows | Similar acronym only; different protocol/model/workflows |
| dowdiness/moondsp | dsp/osc.mbt sine oscillator and test | Audio sample synthesis | Audio-adjacent; no OSC wire packets or addresses |
| moonbit-community/tonyfettes-ghostty | terminal/osc/osc.mbt parser | Terminal operating-system-command escape sequences | Acronym collision, not audio/control protocol |
| colmugx/ai-passport and bobzhang/games | search descriptions and downloaded package research | Embedded/application SDK and games | Fuzzy keyword results, no evidence of central OSC engine |

Public references:
- https://mooncakes.io/docs/thy1016/moonttl
- https://mooncakes.io/docs/Luna-Flow/floating
- https://mooncakes.io/docs/dongxuan2012/oscbridge
- https://github.com/dowdiness/moondsp
- https://github.com/moonbit-community/tonyfettes-ghostty

The research copies and raw searches remain local; no credentials or private account
metadata are part of this public report. Maintenance was assessed via published
version/API/test availability, not invented activity metrics.

## Registry and independence boundaries

All relevant full fingerprints were reviewed, not names alone. MoonBench's timing
statistics/CI regressions, MoonContract's OpenAPI schema/mocks, MoonRecur's calendar
recurrences, MoonShard's content-defined synchronization, MoonAllen's interval
relations, MoonConcept's formal concepts and MoonWell's foundations are outside scope.
MoonLoudness measures audio, while MoonOSC transports typed control commands; no DSP
or loudness engine is included. MoonWire's generic checksummed deterministic framing
is permanently rejected/reserved: MoonOSC size-prefix/SLIP is tied to bounded aligned
OSC payloads and does not introduce a new generic application-frame/checksum protocol.

Although routing, timetags and framing are common building blocks, the original OSC
argument algebra, wire tags/padding, slash-safe patterns, nested immediate semantics,
and inert method-signature plans are a distinct shared core. Extending COMTRADE,
terminal escapes, DSP or calendar recurrence would distort those contracts. Networking
can be integrated by callers using async; duplicating sockets is not needed here.

## Comparison target and compliance limits

The behavioral target is the OSC specification, not a source port. Mature non-MoonBit
OSC servers such as liblo/oscpack provide broader integrations; no claim of replacing
their network servers, discovery or callback APIs. No implementation source is copied.
Supported scope is listed in README: ASCII strings, documented extended tags, nested
bundles, literal brace choices, bounded DP dispatch, stable queue and two OSC stream
encodings. Unicode extensions, recursive descendant wildcard, NTP-era inference,
clock synchronization and hard realtime are deliberately absent.

Conclusion: this scope passes the recorded semantic gate, with real rejected domains
and source-level adjacency analysis. It is not a claim of firstness, exclusivity or an
exhaustive ecosystem census. New evidence can change the assessment.
