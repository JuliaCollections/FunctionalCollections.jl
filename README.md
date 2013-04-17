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

# Building large PersistentVectors is slow, since each "change" creates
# a new one. You can get around this by using TransientVectors, which
# are temporarily mutable.
julia> t = TransientVector{Int}()
Transient{Int64}[]

julia> for i=1:1000000
           push!(t, i)
       end

# When you're done building your TransientVector, you can make it
# persistent in nearly constant time.
julia> v = persist!(t)
Persistent{Int64}[1, 2, 3, 4, 5, ..., 999996, 999997, 999998, 999999, 1000000]

# You cannot mutate a TransientVector after it's been made persistent,
# since it shares structure with the newly created PersistentVector.
julia> push!(t, 1000001)
Error: Cannot mutate Transient after call to persist!
```
