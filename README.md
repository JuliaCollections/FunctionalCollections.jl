**Persistent Data Strucrues**

Functional and persistent data structures for Julia. This is a work in
progress and is currently not optimized for performance.

### Implemented:

:white_check_mark: **PersistentVector**

:white_check_mark: **PersistentHashMap**

:white_check_mark: **PersistentArrayMap**

:x: **PersistentSet**

### PersistentVector

PersistentVectors are immutable, sequential, random-access data
structures: functional Arrays.

```.jl
julia> using PersistentDataStructures

julia> v = PersistentVector{Int}()
Persistent{Int64}[]

# "Changing" a PersistentVector does *not* mutate it, but instead
# returns a new PersistentVector.
julia> v2 = append(v, 1)
Persistent{Int64}[1]

julia> v
Persistent{Int64}[]

julia> peek(v2)
1

julia> pop(v2)
Persistent{Int64}[]

julia> is(v, pop(pv))
false

julia> v == pop(v)
true

# Elements of a PersistentVector can be accessed randomly.
julia> v = PersistentVector{Int64}()

julia> for i=1:10000 v=append(v, i) end

julia> v[5000]
5000

julia> v[end]
10000

julia> v[end+1]
BoundsError()

# Since a PersistentVector cannot be mutated, it does not implement
# setindex!; instead, use update.
julia> v2 = update(v, 5000, 1)
Persistent[1, 2, 3, 4, 5, ..., 49996, 49997, 49998, 49999, 50000]

julia> v2[5000]
1

julia> v[5000]
5000

# PersistentVectors are iterables as well
julia> for el in PersistentVector{ASCIIString}(["foo", "bar", "baz"])
           println(el)
       end
foo
bar
baz

julia> map((x)->x+1, PersistentVector{Int}([1,2,3]))
Persistent{Int64}[2,3,4]
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
