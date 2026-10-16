# MoonOSC

A portable, bounded **OSC 1.0 (26 March 2002) core library profile** in MoonBit:
required i/f/s/b wire types, all normative segment-pattern rules, all-matching-method
dispatch plans, and indivisible timed bundle batches. Not an OSC 1.1 or full-server
conformance claim. It performs no socket IO and invokes no callbacks.

**协议目标、完整必需语义、永久排除边界和三个可执行案例：**
[OSC 1.0 conformance map](docs/osc-1.0-conformance.md)。
严格入口覆盖本配置的全部必需语义；实际计时、调用和连续执行由宿主履行。

## Install

```sh
moon add CYang-dep/moonosc@0.2.0
```

In your moon.pkg:

```text
import { "CYang-dep/moonosc" @osc }
```

```moonbit
let packet = @osc.Message({ address: "/mixer/gain", arguments: [@osc.float_argument(0.5)] })
let wire = @osc.encode_osc10(packet)
let recovered = @osc.decode_osc10(wire)
```

These functions raise OscError; handle errors at your application boundary.
The complete public interface is [pkg.generated.mbti](pkg.generated.mbti).

## Delivered workflows

| Consumer | Input and processing | Observable result | Run |
| --- | --- | --- | --- |
| Audio tools | Typed gain message, codec roundtrip, brace-pattern fanout, exact signature checks | Two accepted destinations; no callbacks before validation | moon run examples/audio |
| Interactive media | Future screen show/commit plus nested light cue | One indivisible screen batch and one light batch | moon run examples/media |
| Device gateways | SLIP input arriving one byte at a time, decoding and JSON diagnostics | One reconstructed packet; exact replay including escaped bytes | moon run examples/device |

All examples are deterministic and assertion-backed. They require no devices,
servers, credentials, or audio driver.

## Capabilities

- OSC messages and nested bundles; canonical big-endian fields and zero padding;
  strict full-payload consumption, type tags and bounded lengths/depth/counts.
- Core tags i f s b; generic opt-in tags h d t S c r m T F N I and recursive [...] arrays.
  Floats are raw IEEE bits: NaN payloads and signed zero are preserved.
- Non-NUL ASCII OSC strings; character arguments restricted to ASCII 0..127.
  This intentionally does not implement non-ASCII protocol extensions.
- Compiled * ? [ranges] [!ranges] {literal,alternatives} patterns. Wildcards do
  not cross slashes. Brace choices are literal segment strings, including empty alternatives;
  nested alternatives, recursive //, and generic regex are not supported.
- Ordered method registry and signature-aware inert dispatch plans; fanout has a
  shared work budget. Default contract failure is all-or-nothing; partial plans
  are explicit. This is not an indexed router or executing RPC framework.
- NTP-era-zero timetags, explicit Unix conversion (1900 through the 2036 rollover),
  checked tick arithmetic; generic flatten lets nested immediate inherit parent time,
  whereas strict APIs compare raw child times without repair.
- Generic per-message Scheduler: transactional admission, stable minheap, cancellation, polling,
  explicit exclusive late-event cutoff and clearing without ticket reuse.
- Transactional size-prefix and SLIP feeds with bounded frame/chunk/output counts,
  split-header/escape support, EOF checks, reset and rollback on failure.
- Strict hex utilities, validated structural summaries and moonosc/1 lossless
  JSON tagged arrays. All numeric values use fixed-width hex, never JSON numbers.

See [architecture](docs/architecture.md), [security](docs/security.md),
[JSON schema](docs/json-schema.md), [attribution](NOTICE.md),
[AI disclosure](AI_USAGE.md), and [changelog](CHANGELOG.md).

## Strict profile versus compatibility APIs

Use `encode_osc10` / `decode_osc10` and `Osc10Scheduler` for the documented profile.
`plan_osc10(packet, absolute_now)` returns owned batches; `poll(now,max_batches=1)`
can return many messages in one batch. Run them consecutively, preserving message
order and passing identical arguments to every matching method. Never insert an
unrelated callback/await between messages in a batch. See the host execution loop
in the conformance map; the library does not execute it for you.

Generic `encode` / `decode` additionally support the optional OSC 1.0 tag table
h/t/d/S/c/r/m/T/F/N/I/arrays. These are opt-in, not OSC 1.1 claims.
Generic `flatten` / `Scheduler` retain per-message behavior and nested-immediate
inheritance for compatibility: they do **not** provide atomic bundle execution.
Strict APIs reject a child raw timetag earlier than its parent, including sentinel 1
under a future parent. No implicit type coercion or missing-typetag guessing.

## Validation

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
moon build --deny-warn --target wasm-gc
python scripts/reference_vectors.py --target wasm-gc
python scripts/audit.py
moon run examples/conformance
```

Repeat check/test/build/examples for wasm, js and native.
Native execution requires a C toolchain (CI uses Ubuntu). CI installs the official
stable toolchain on clean runners and tests all four targets. Local development
was initially checked using Moon 0.1.20260920 and then migrated to the canonical
Moon 0.1.20261012 syntax after the first real CI run. Use Moon 0.1.20261012
or newer; CI logs record the actual release.

The test suite includes 256 full-model roundtrips with every shortened message
prefix rejected, 240 wildcard pairs against a recursive short-input oracle,
512 queue mutations against a scan model, every split of both stream encodings,
and 256 independently encoded Python stdlib message/bundle vectors. These are
correctness checks, not performance claims or proof of complete conformance.

The 0.2.0 tests additionally check every required pattern form, exact core wire,
optional-type exclusion, malformed input, strict parent/child timing, owned snapshots,
transactional batch admission and 96 batches against an independent sorted model.

## Boundaries

This is a reusable library, not a complete OSC server. Users provide transports,
clock synchronization, NTP-era choice, authentication, thread synchronization,
application contracts, and callback execution. No hard-realtime guarantees,
audio synthesis, DSP, discovery, delivery acknowledgement, clock drift model,
or automatic competition registration. The core profile permanently excludes OSC
1.1 recursive `//`, Unicode protocol fields, recursive brace-pattern extensions,
legacy typetag guessing and implicit numeric coercion. Malformed packets are rejected,
not repaired. See the conformance map for exact limits and host obligations.

## License

Original implementation under Apache-2.0, relying on MoonBit core only.
Bounded ecosystem research and rejected alternatives are documented in
[duplicate-check](docs/competition/duplicate-check.md); it is not a claim of uniqueness.
