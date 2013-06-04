**Functional Collections v0.0.0**

Functional and persistent data structures for Julia. This is a work in
progress and is currently not optimized for performance.

### Installation

```.jl
julia> Pkg.add("FunctionalCollections")

julia> using FunctionalCollections
```

### Exports

- `PersistentVector / pvec`
- `PersistentHashMap / phmap`
- `PersistentArrayMap`
- `PersistentSet / pset`
- `PersistentList / plist`
- `PersistentQueue / pqueue`

[src/FunctionalCollections.jl](https://github.com/zachallaun/FunctionalCollections.jl/blob/master/src/FunctionalCollections.jl)
contains all of the package's exports, though all of the collections
also implement built-in functions from `Base`.

### PersistentVector

Persistent vectors are immutable, sequential, random-access data
structures, with performance characteristics similar to arrays.

```.jl
julia> v = pvec([1, 2, 3, 4, 5])
Persistent{Int64}[1, 2, 3, 4, 5]
```

Since persistent vectors are immutable, "changing" operations return a
new vector instead of modifying the original.

```.jl
julia> append(v, 6)
Persistent{Int64}[1, 2, 3, 4, 5, 6]

# v hasn't changed
julia> v
Persistent{Int64}[1, 2, 3, 4, 5]
```

Persistent vectors are random-access structures, and can be indexed
into just like arrays.

```.jl
julia> v[3]
3
```

But since they're immutable, it doesn't make sense to define index
assignment (`v[3] = 42`) since assignment implies change. Instead,
`assoc` returns a new persistent vector with some value associated
with a given index.

```.jl
julia> assoc(v, 3, 42)
Persistent{Int64}[1, 2, 42, 4, 5]
```

Three functions, `push`, `peek`, and `pop`, make up the persistent
vector stack interface. `push` is simply an alias for `append`, `peek`
returns the last element of the vector, and `pop` returns a new vector
_without_ the last element.

```.jl
julia> peek(v)
5

julia> pop(v)
Persistent{Int64}[1, 2, 3, 4]
```

Persistent vectors also support iteration and higher-order sequence
operations.

```.jl
julia> for el in pvec(["foo", "bar", "baz"])
           println(el)
       end
foo
bar
baz

julia> map(x -> x * 2, v)
Persistent{Int64}[1, 4, 6, 8, 10]

julia> filter(iseven, v)
Persistent{Int64}[2, 4]
```

### PersistentArrayMap

PersistentArrayMaps are immutable dictionaries implemented as Arrays of
key-value pairs. This means that the time complexity of most operations
on them is O(n). They can be quickly created, though, and useful at
small sizes.

```.jl
julia> using PersistentDataStructures

julia> m = PersistentArrayMap((1, "one"))
Persistent{Int64, ASCIIString}[1 => one]

julia> m2 = assoc(m, 2, "two")
Persistent{Int64, ASCIIString}[1 => one, 2 => two]

julia> m == m2
false

julia> dissoc(m2, 2)
Persistent{Int64, ASCIIString}[1 => one]

julia> m == dissoc(m2, 2)
true
```

### PersistentHashMap

PersistentHashMaps are the immutable counterpart of the build-in Dict
type. Major operations are nearly constant time &mdash; O(log<sub>32</sub>n).

### PersistentSet

PersistentSets are immutable sets. Along with the usual set interface,
`conj(s::PersistentSet, val)` returns a set with an element added
(conjoined), and `disj(s::PersistentSet, val` returns a set with an
element removed (disjoined).

### TODO:

#### PersistentQueue

- queue => pqueue

#### BitmappedTrie

- comment `mask` to indicate index-from-1 assumption

#### PersistentVector

- constant time `rest` by adding an initial index offset
- quick slicing with initial offset and structure deletion
- pvec mask should take the pvec even though it doesn't use it
- move extra pvec constructor to the type definition
