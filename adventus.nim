const
  Comments = false

# Absolute Addition Operator
template `|+|`*(a,b: typed): untyped = (abs(a) + abs(b))
# Assign & Return Operator
template `:=`*(a, b): untyped {.dirty.}= (let a = b; a)

template inputf*(ex: int = 0): untyped =
  instantiationInfo(-1, true).filename & "/../input" & $ex

iterator ilines*(f: File): (int, TaintedString) =
  var i: int = 0
  for ln in lines(f):
    when Comments:
      if ln[0] != '#':
        yield (i, ln)
    else:
      yield (i, ln)
    i += 1

iterator ilines*(filename: string): (int, TaintedString) =
  var f = open(filename)
  for i, ln in ilines(f):
    yield (i, ln)
  close(f)

template des*(s: cstring; i: int): cstring =
  cast[cstring](addr s[i])

proc bfind*[T, S](a: T; item: S or set[S]; s: SomeNumber): int {.inline.}=
  result = s
  for i in s..<len(a): #items(a):
    when item is set[S]:
      if a[i] in item: return
    else:
      if a[i] == item: return
    inc(result)
  result = -1

const
  bflen = 1024
  slinesStatic = true

template cs(a): string = cast[string](a)
from strutils import strip
iterator slines*(f: File; s: char or set[char]): (int, TaintedString) =
  var (i, ln, rs) = (0, 1, "")
  while ln != 0:
    var
      p: int
      buf: array[bflen, char]
    ln = readBuffer(f, addr buf, bflen)
    while (n := bfind(buf, s, p)) != -1:
      add(rs, cs(buf[p..n-1]))
      yield (i, rs)
      (p, i, rs) = (n+1, i+1, "")
    add(rs, cs(buf[p..^1]))
  yield (i, strip(rs, leading = false, chars = {'\0'}))

from parseutils import
  parseint, parseuint, parsefloat,
  parseBiggestInt, parseBiggestUint, parseBiggestFloat
# prettier (imo) parsing, with parsed return value
template q(T,F) = (var r: T; discard F(s,r); r)
proc parse*(T: typedesc; s: string): T =
  when T is int64:
    q(int64, parseBiggestInt)
  elif T is SomeSignedInt:
    q(int, parseInt)
  elif T is uint64:
    q(uint64, parseBiggestUInt)
  elif T is SomeUnsignedInt:
    q(uint, parseUInt)
  elif T is float64:
    q(float64, parseFloat64)
  elif T is SomeFloat:
    q(float, parseFloat)


