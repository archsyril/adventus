const
  Comments = false

# Absolute Addition Operator
template `|+|`*(a,b: typed): untyped = (abs(a) + abs(b))
# Assign & Return Operator
template `:=`*(a, b): untyped {.dirty.}= (let a = b; a)

template inputf*(ex: int = 0): untyped =
  instantiationInfo(-1, true).filename & "/../input" & $ex

from tables import Table, contains, `[]=`, `[]`, `$`, pairs
export
  tables.Table, tables.contains, tables.pairs,
  tables.`[]=`, tables.`[]`, tables.`$`
proc force*[K,V](tbl: var Table[K, seq[V]]; k: K; v: V) =
  if k in tbl:
    add(tbl[k], v)
  else:
    tbl[k] = @[v]
template `[]=`*[K,V](tbl: var Table[K, seq[V]]; k: K; v: V) =
  force(tbl, k, v)

template bracketAccess*(T: typedesc; where: untyped): untyped {.dirty.}=
  template `[]` *(t: T; i: int): typeof(t.where[i]) =
    t.where[i]
  template `[]=`*(t: T; i: int; e: typeof(t.where[i])): void =
    t.where[i] = e
  template items*(t: T): untyped =
    items(t.where)

iterator chop*(i: int): int8 =
  var i = i
  while i > 0:
    yield int8 i mod 10
    i = i div 10

iterator ichop*(i: int): (int, int8) =
  var j = 0
  for i in chop(i):
    yield (j, i)
    j += 1

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

const bflen = 1024
template cs(a): string = cast[string](a)
from strutils import strip, Whitespace
export strutils.strip, strutils.Whitespace
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
  yield (i, strip(rs, leading = false, chars = Whitespace + {'\0'}))

iterator slines*(fn: string; s: char or set[char]): (int, TaintedString) =
  let f = open(fn)
  for i, l in slines(f, s):
    yield (i, l)
  close(f)

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


