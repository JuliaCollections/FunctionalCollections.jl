**Persistent Data Strucrues**

Functional and persistent data structures for Julia. This is a work in
progress and is currently not optimized for performance.

### Implemented:

:white_check_mark:   **PersistentVector**

:x:   **PersistentHashMap**

:x:   **PersistentSet**

### Usage

```.jl
julia> using PersistentDataStructures

# A PersistentVector is an immutable, sequential, random-access data
# structure: a functional Array.
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
