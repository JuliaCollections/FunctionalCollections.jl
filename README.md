# FunctionalCollections

[![Build Status](https://travis-ci.org/JuliaCollections/FunctionalCollections.jl.svg)](https://travis-ci.org/JuliaCollections/FunctionalCollections.jl)
[![FunctionalCollections](http://pkg.julialang.org/badges/FunctionalCollections_0.3.svg)](http://pkg.julialang.org/?pkg=FunctionalCollections&ver=0.3)

Functional and persistent data structures for Julia. This is a work in
progress and is currently not optimized for performance.

**NOTE:** The `master` branch of `FunctionalCollections` is for Julia v0.7 and up. For earlier Julia versions please use FunctionalCollections v0.3.x.

### Installation

```.jl
julia> Pkg.add("FunctionalCollections")

julia> using FunctionalCollections
```

### Exports

```
Collection         | Abbrev
----------------------------
PersistentVector   | pvec
PersistentHashMap  | phmap
PersistentArrayMap |
PersistentSet      | pset
PersistentList     | plist
PersistentQueue    | pqueue
```

[src/FunctionalCollections.jl](https://github.com/JuliaLang/FunctionalCollections.jl/blob/master/src/FunctionalCollections.jl)
contains all of the package's exports, though many built-ins are also
implemented.

### PersistentVector

Persistent vectors are immutable, sequential, random-access data
structures, with performance characteristics similar to arrays.

```.jl
julia> v = @Persistent [1, 2, 3, 4, 5]
Persistent{Int64}[1, 2, 3, 4, 5]
```

Since persistent vectors are immutable, "changing" operations return a
new vector instead of modifying the original.

```.jl
julia> append(v, [6, 7])
Persistent{Int64}[1, 2, 3, 4, 5, 6, 7]

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
vector stack interface. `push` adds a single element (whereas `append`
adds all elements in the given collection, starting from the left),
`peek` returns the last element of the vector, and `pop` returns a new
vector _without_ the last element.

```.jl
julia> push(v, 6)
Persistent{Int64}[1, 2, 3, 4, 5, 6]

julia> peek(v)
5

julia> pop(v)
Persistent{Int64}[1, 2, 3, 4]
```

Persistent vectors also support iteration and higher-order sequence
operations.

```.jl
julia> for el in @Persistent ["foo", "bar", "baz"]
           println(el)
       end
foo
bar
baz

julia> map(x -> x * 2, v)
Persistent{Int64}[2, 4, 6, 8, 10]

julia> filter(iseven, v)
Persistent{Int64}[2, 4]
```

### PersistentHashMap

Persistent hash maps are immutable, unordered, associative structures,
similar to the built-in `Dict` type.

```.jl
julia> name = @Persistent Dict(:first => "Zach", :last => "Allaun")
Persistent{Symbol, String}[last => Allaun, first => Zach]
```

They can be queried in a manner similar to the dictionaries.

```.jl
julia> name[:first]
"Zach"

julia> get(name, :middle, "")
""
```

With persistent vectors, `assoc` is used to associate a value with an
index; with persistent hash maps, you use it to associate a value with
an arbitrary key. To dissociate a key/value pair, use `dissoc`.

```.jl
julia> fullname = assoc(name, :middle, "Randall")
Persistent{Symbol, String}[last => Allaun, first => Zach, middle => Randall]

julia> dissoc(fullname, :middle)
Persistent{Symbol, String}[last => Allaun, first => Zach]
```

`Base.map` is defined for persistent hash maps. The function argument
should expect a `(key, value)` tuple and return a `(key, value)`
tuple. This function will be applied to each key-value pair of the
hash map to construct a new one.

```.jl
julia> mapkeys(f, m::PersistentHashMap) =
	       map(kv -> (f(kv[1]), kv[2]), m)

julia> mapkeys(string, fullname)
Persistent{String, String}[last => Allaun, middle => Randall, first => Zach]
```

### PersistentArrayMap

PersistentArrayMaps are immutable dictionaries implemented as Arrays of
key-value pairs. This means that the time complexity of most operations
on them is O(n). They can be quickly created, though, and useful at
small sizes.

```.jl
julia> m = PersistentArrayMap((1, "one"))
Persistent{Int64, String}Pair{Int64,String}[1=>"one"]

julia> m2 = assoc(m, 2, "two")
Persistent{Int64, String}Pair{Int64,String}[1=>"one", 2=>"two"]

julia> m == m2
false

julia> dissoc(m2, 2)
Persistent{Int64, String}Pair{Int64,String}[1 => one]

julia> m == dissoc(m2, 2)
true
```

### PersistentSet

PersistentSets are immutable sets. Along with the usual set interface,
`conj(s::PersistentSet, val)` returns a set with an element added
(conjoined), and `disj(s::PersistentSet, val` returns a set with an
element removed (disjoined).

### TODO:

#### General

- Ints vs Uints w.r.t. bitwise operations
- `children` instead of `arrayof`
- standardize "short-fn" interfaces:
- `lastchild` instead of `arrayof(node)[end]`
- `peek` should become `pop`, `pop` should become `butlast`
- What is Base doing for Arrays w.r.t. `boundscheck!`, can we drop boundcheck for iteration

```jl
# currently
pvec([1,2,3,4,5])
pset(1,2,3,4,5)

# should be
pvec(1,2,3,4,5)
pset(1,2,3,4,5)
```

- `@Persistent` macro sugar for hi-jacking built-in syntax:

```jl
@Persistent Dict("foo" => 1, "bar" => 2, "baz" => 3)
# creates a phmap

@Persistent [1, 2, 3, 4, 5]
# creates a pvec
```

#### PersistentQueue

- queue => pqueue

#### BitmappedTrie

- comment `mask` to indicate index-from-1 assumption

#### PersistentVector

- constant time `rest` by adding an initial index offset
- quick slicing with initial offset and structure deletion
- pvec mask should take the pvec even though it doesn't use it
- move extra pvec constructor to the type definition

#### PersistentHashMap

- the repr of values should be printed, not the string
- printing breaks after dissocing
