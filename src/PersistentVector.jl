abstract BitmappedVector

immutable PersistentVector <: BitmappedVector
    trie::BitmappedTrie
    tail::Array
    length::Int
end
PersistentVector() = PersistentVector(BitmappedTrie(), Any[], 0)

mask(v::BitmappedVector, i::Int) = i & (trielen - 1)

boundscheck!(v::BitmappedVector, i::Int) =
    0 < i <= v.length || error(BoundsError(), " :: Index $i out of bounds ($(v.length))")

Base.length(v::BitmappedVector) = v.length
Base.endof(v::BitmappedVector) = v.length

import Base.==
==(v1::BitmappedVector, v2::BitmappedVector) = v1.tail == v2.tail && v1.trie == v2.trie

function Base.getindex(v::BitmappedVector, i::Int)
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        v.tail[mask(v, i - 1) + 1]
    else
        v.trie[i][mask(v, i - 1) + 1]
    end
end

peek(v::BitmappedVector) = v[end]

function append(v::PersistentVector, el)
    if length(v.tail) < trielen
        newtail = copy_to_len(v.tail, 1 + length(v.tail))
        newtail[end] = el
        PersistentVector(v.trie, newtail, 1 + v.length)
    else
        PersistentVector(append(v.trie, v.tail), Any[el], 1 + v.length)
    end
end

function update(v::PersistentVector, i::Int, el)
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        newtail = v.tail[1:end]
        newtail[mask(v, i - 1) + 1] = el
        PersistentVector(v.trie, newtail, v.length)
    else
        newnode = v.trie[i][1:end]
        newnode[mask(v, i - 1) + 1] = el
        PersistentVector(update(v.trie, i, newnode), v.tail, v.length)
    end
end

function pop(v::PersistentVector)
    if isempty(v.tail)
        newtail = peek(v.trie)[1:end]
        pop!(newtail)
        PersistentVector(pop(v.trie), newtail, v.length - 1)
    else
        newtail = v.tail[1:end]
        pop!(newtail)
        PersistentVector(v.trie, newtail, v.length - 1)
    end
end

type TransientVector <: BitmappedVector
    trie::TransientBitmappedTrie
    tail::Array
    length::Int
    persistent::Bool
end
TransientVector() = TransientVector(TransientBitmappedTrie(), Any[], 0, false)

function persist!(tv::TransientVector)
    tv.persistent = true
    PersistentVector(persist!(tv.trie), tv.tail, tv.length)
end

function Base.push!(v::TransientVector, el)
    transientcheck!(v)
    v.length += 1
    if length(v.tail) < trielen
        push!(v.tail, el)
    else
        push!(v.trie, v.tail)
        v.tail = Any[el]
    end
    v
end

function Base.setindex!(v::TransientVector, el, i::Real)
    transientcheck!(v)
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        v.tail[mask(v, i - 1) + 1] = el
    else
        v.trie[i][mask(v, i - 1) + 1] = el
    end
    el
end

function PersistentVector(self::Array)
    if length(self) <= trielen
        PersistentVector(BitmappedTrie(), self, length(self))
    else
        tv = TransientVector()
        for el in self
            push!(tv, el)
        end
        persist!(tv)
    end
end

# Slow iteration
Base.start(pv::PersistentVector) = 1
Base.done(pv::PersistentVector, i::Int) = i > pv.length
Base.next(pv::PersistentVector, i::Int) = (pv[i], i+1)

function Base.map(f::Function, pv::PersistentVector)
    tv = TransientVector()
    for el in pv
        push!(tv, f(el))
    end
    persist!(tv)
end

function Base.hash(pv::PersistentVector)
    h = hash(length(pv))
    for el in pv
        h = Base.bitmix(h, int(hash(el)))
    end
    uint(h)
end

function print_elements(io, pv, range)
    for i=range
        print(io, "$(pv[i]), ")
    end
end

function print_vec(io::IO, t, head::String)
    print(io, "$head[")
    if length(t) < 50
        print_elements(io, t, 1:length(t)-1)
    else
        print_elements(io, t, 1:25)
        print(io, "..., ")
        print_elements(io, t, length(t)-25:length(t)-1)
    end
    if length(t) >= 1
        print(io, "$(t[end])]")
    else
        print(io, "]")
    end
end

Base.show(io::IO, pv::PersistentVector) = print_vec(io, pv, "Persistent")
Base.show(io::IO, tv::TransientVector) = print_vec(io, tv, "Transient")
