"""Independent Python stdlib wire encoder; does not import MoonOSC implementation."""
import argparse
import re
import struct
import subprocess


def osc_string(value):
    raw = value.encode("ascii") + b"\0"
    return raw + b"\0" * (-len(raw) % 4)


def expected():
    out = []
    for i in range(128):
        message = (osc_string("/vector/" + str(i)) + osc_string(",ifsb[TN]")
                   + struct.pack(">iI", i * 7919 - 1, 0x3f000000 + i)
                   + osc_string("hello") + struct.pack(">I", 4)
                   + bytes([0, 0xc0, 0xdb, i]))
        bundle = (b"#bundle\0" + struct.pack(">Q", 0x0123456789abcdef)
                  + struct.pack(">I", len(message)) + message)
        out.extend([message.hex(), bundle.hex()])
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", default="wasm-gc")
    args = parser.parse_args()
    result = subprocess.run(["moon", "run", "examples/vectors", "--target", args.target],
                            check=True, text=True, stdout=subprocess.PIPE)
    actual = result.stdout.splitlines()
    if not all(re.fullmatch(r"[0-9a-f]+", x) for x in actual):
        raise SystemExit("Unexpected non-hex reference output")
    wanted = expected()
    if actual != wanted:
        raise SystemExit("Independent wire-vector mismatch")
    print("256 independently encoded message/bundle vectors agree (100%)")


if __name__ == "__main__":
    main()
