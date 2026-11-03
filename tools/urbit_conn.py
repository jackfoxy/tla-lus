"""A minimal client for a running ship's `.urb/conn.sock` (R4.0d).

Nouns are Python ints (atoms) and 2-tuples (cells). `jam`/`cue` are the
standard Urbit serialization; a conn.c message is newt-framed: one 0x00
version byte, a u32 little-endian length, then the jam's bytes (LSB first).
Measured against `urbit eval -jn` on vere 4.6.
"""
import socket
import struct


# ------------------------------------------------------------------ nouns ---
def cord(s: str) -> int:
    """A Hoon cord/term/knot: UTF-8 bytes, least significant first."""
    return int.from_bytes(s.encode(), "little")


def uncord(a: int) -> str:
    return a.to_bytes((a.bit_length() + 7) // 8, "little").decode(errors="replace")


def tup(*xs):
    """[a b c] -> (a, (b, c)); a trailing ~ must be passed explicitly."""
    out = xs[-1]
    for x in reversed(xs[:-1]):
        out = (x, out)
    return out


def lst(xs):
    """A Hoon list: null-terminated."""
    return tup(*xs, 0) if xs else 0


def path(*segs):
    return lst([cord(s) for s in segs])


def unit(x):
    return 0 if x is None else (0, x)


# -------------------------------------------------------------- jam / cue ---
class _Bits:
    def __init__(self):
        self.v = 0
        self.n = 0

    def put(self, val: int, width: int):
        self.v |= (val & ((1 << width) - 1)) << self.n
        self.n += width


def _mat(b: _Bits, a: int):
    if a == 0:
        b.put(1, 1)
        return
    w = a.bit_length()
    c = w.bit_length()
    b.put(1 << c, c + 1)          # c zeros then a one
    b.put(w, c - 1)               # w without its top bit
    b.put(a, w)


def jam(noun) -> int:
    b, seen = _Bits(), {}
    stack = [noun]
    while stack:
        x = stack.pop()
        key = ("a", x) if isinstance(x, int) else ("c", id(x))
        if isinstance(x, int):
            if key in seen and seen[key].bit_length() < x.bit_length():
                b.put(3, 2)
                _mat(b, seen[key])
                continue
            seen.setdefault(key, b.n)
            b.put(0, 1)
            _mat(b, x)
        else:
            if key in seen:
                b.put(3, 2)
                _mat(b, seen[key])
                continue
            seen[key] = b.n
            b.put(1, 2)
            stack.append(x[1])
            stack.append(x[0])
    return b.v


def cue(a: int):
    pos, refs = 0, {}

    def bit(i):
        return (a >> i) & 1

    def rub(i):
        c = 0
        while bit(i + c) == 0:
            c += 1
            if c > 64 * 1024:
                raise ValueError("cue: bad rub")
        if c == 0:
            return 1, 0
        w = ((a >> (i + c + 1)) & ((1 << (c - 1)) - 1)) | (1 << (c - 1))
        val = (a >> (i + 2 * c)) & ((1 << w) - 1)
        return 2 * c + w, val

    # iterative to survive deep lists
    stack, out = [("go", 0)], []
    while stack:
        op, i = stack.pop()
        if op == "go":
            if bit(i) == 0:
                n, v = rub(i + 1)
                refs[i] = v
                out.append((1 + n, v))
            elif bit(i + 1) == 0:
                stack.append(("cell", i))
                stack.append(("right", i))
                stack.append(("go", i + 2))
            else:
                n, r = rub(i + 2)
                out.append((2 + n, refs[r]))
        elif op == "right":
            ln, _ = out[-1]
            stack.append(("go", i + 2 + ln))
        else:  # cell
            (lr, r), (ll, l) = out.pop(), out.pop()
            refs[i] = (l, r)
            out.append((2 + ll + lr, (l, r)))
    return out[0][1]


# ------------------------------------------------------------------- conn ---
def newt(noun) -> bytes:
    j = jam(noun)
    body = j.to_bytes(max(1, (j.bit_length() + 7) // 8), "little")
    return b"\x00" + struct.pack("<I", len(body)) + body


def send(pier: str, noun, timeout=600):
    """One request, one reply: `[rid cmd ...]` -> the reply noun."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)
        s.connect(f"{pier}/.urb/conn.sock")
        s.sendall(newt(noun))
        head = b""
        while len(head) < 5:
            chunk = s.recv(5 - len(head))
            if not chunk:
                raise ConnectionError("conn: closed before a reply")
            head += chunk
        (n,) = struct.unpack("<I", head[1:5])
        body = b""
        while len(body) < n:
            chunk = s.recv(min(1 << 20, n - len(body)))
            if not chunk:
                raise ConnectionError("conn: short reply")
            body += chunk
    return cue(int.from_bytes(body, "little"))
