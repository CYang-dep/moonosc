# MoonOSC

A portable, bounded Open Sound Control library in MoonBit. It combines wire codecs,
address-pattern dispatch, deterministic bundle scheduling, and incremental stream
framing. It performs no socket IO and invokes no callbacks.

## Install

```sh
moon add CYang-dep/moonosc@0.1.0
```

In your moon.pkg:

```text
import { "CYang-dep/moonosc" @osc }
```

```moonbit
let packet = @osc.Message({ address: "/mixer/gain", arguments: [@osc.float_argument(0.5)] })
let wire = @osc.encode(packet)
let recovered = @osc.decode(wire)
```

These functions raise OscError; handle errors at your application boundary.
The complete public interface is [pkg.generated.mbti](pkg.generated.mbti).

## Delivered workflows

| Consumer | Input and processing | Observable result | Run |
| --- | --- | --- | --- |
| Audio tools | Typed gain message, codec roundtrip, brace-pattern fanout, exact signature checks | Two accepted destinations; no callbacks before validation | moon run examples/audio |
| Interactive media | Absolute timed bundle with nested immediate cues, heap queue, stable tickets | No early output; both cues retain enclosing time and wire order | moon run examples/media |
| Device gateways | SLIP input arriving one byte at a time, decoding and JSON diagnostics | One reconstructed packet; exact replay including escaped bytes | moon run examples/device |

All examples are deterministic and assertion-backed. They require no devices,
servers, credentials, or audio driver.

## Capabilities

- OSC messages and nested bundles; canonical big-endian fields and zero padding;
  strict full-payload consumption, type tags and bounded lengths/depth/counts.
- Tags i f s b h d t S c r m T F N I and recursive [...] arrays.
  Floats are raw IEEE bits: NaN payloads and signed zero are preserved.
- Non-NUL ASCII OSC strings; character arguments restricted to ASCII 0..127.
  This intentionally does not implement non-ASCII protocol extensions.
- Compiled * ? [ranges] [!ranges] {literal,alternatives} patterns. Wildcards do
  not cross slashes. Brace choices must be nonempty literal segment strings;
  nested alternatives, recursive //, and generic regex are not supported.
- Ordered method registry and signature-aware inert dispatch plans; fanout has a
  shared work budget. Default contract failure is all-or-nothing; partial plans
  are explicit. This is not an indexed router or executing RPC framework.
- NTP-era-zero timetags, explicit Unix conversion (1900 through the 2036 rollover),
  checked tick arithmetic; nested immediate bundles inherit enclosing time.
- Transactional scheduler admission, stable minheap, cancellation, polling,
  explicit exclusive late-event cutoff and clearing without ticket reuse.
- Transactional size-prefix and SLIP feeds with bounded frame/chunk/output counts,
  split-header/escape support, EOF checks, reset and rollback on failure.
- Strict hex utilities, validated structural summaries and moonosc/1 lossless
  JSON tagged arrays. All numeric values use fixed-width hex, never JSON numbers.

See [architecture](docs/architecture.md), [security](docs/security.md),
[JSON schema](docs/json-schema.md), [attribution](NOTICE.md),
[AI disclosure](AI_USAGE.md), and [changelog](CHANGELOG.md).

## Validation

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
moon build --deny-warn --target wasm-gc
python scripts/reference_vectors.py --target wasm-gc
python scripts/audit.py
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

## Boundaries

This is a reusable library, not a complete OSC server. Users provide transports,
clock synchronization, NTP-era choice, authentication, thread synchronization,
application contracts, and callback execution. No hard-realtime guarantees,
audio synthesis, DSP, discovery, delivery acknowledgement, clock drift model,
or automatic competition registration. Malformed packets are rejected, not repaired.

## License

Original implementation under Apache-2.0, relying on MoonBit core only.
Bounded ecosystem research and rejected alternatives are documented in
[duplicate-check](docs/competition/duplicate-check.md); it is not a claim of uniqueness.
