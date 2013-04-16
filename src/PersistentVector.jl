abstract BitmappedVector

immutable PersistentVector{T} <: BitmappedVector
    trie::BitmappedTrie
    tail::Array{T}
    length::Int

    PersistentVector(trie::BitmappedTrie, tail::Array{T}, length::Int) =
        new(trie, tail, length)
    PersistentVector() = new(BitmappedTrie(), T[], 0)
end

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

function append{T}(v::PersistentVector{T}, el)
    if length(v.tail) < trielen
        newtail = copy_to_len(v.tail, 1 + length(v.tail))
        newtail[end] = el
        PersistentVector{T}(v.trie, newtail, 1 + v.length)
    else
        PersistentVector{T}(append(v.trie, v.tail), T[el], 1 + v.length)
    end
end

function update{T}(v::PersistentVector{T}, i::Int, el::T)
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        newtail = v.tail[1:end]
        newtail[mask(v, i - 1) + 1] = el
        PersistentVector{T}(v.trie, newtail, v.length)
    else
        newnode = v.trie[i][1:end]
        newnode[mask(v, i - 1) + 1] = el
        PersistentVector{T}(update(v.trie, i, newnode), v.tail, v.length)
    end
end

function pop{T}(v::PersistentVector{T})
    if isempty(v.tail)
        newtail = peek(v.trie)[1:end]
        pop!(newtail)
        PersistentVector{T}(pop(v.trie), newtail, v.length - 1)
    else
        newtail = v.tail[1:end]
        pop!(newtail)
        PersistentVector{T}(v.trie, newtail, v.length - 1)
    end
end

type TransientVector{T} <: BitmappedVector
    trie::TransientBitmappedTrie
    tail::Array{T}
    length::Int
    persistent::Bool

    TransientVector(trie::TransientBitmappedTrie,
                    tail::Array{T},
                    length::Int,
                    persistent::Bool) = new(trie, tail, length, persistent)
    TransientVector() = new(TransientBitmappedTrie(), Any[], 0, false)
end


function persist!{T}(tv::TransientVector{T})
    tv.persistent = true
    PersistentVector{T}(persist!(tv.trie), tv.tail, tv.length)
end

function Base.push!{T}(v::TransientVector{T}, el::T)
    transientcheck!(v)
    v.length += 1
    if length(v.tail) < trielen
        push!(v.tail, el)
    else
        push!(v.trie, v.tail)
        v.tail = T[el]
    end
    v
end

function Base.setindex!{T}(v::TransientVector, el::T, i::Real)
    transientcheck!(v)
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        v.tail[mask(v, i - 1) + 1] = el
    else
        v.trie[i][mask(v, i - 1) + 1] = el
    end
    el
end

function PersistentVector{T}(self::Array{T})
    if length(self) <= trielen
        PersistentVector{T}(BitmappedTrie(), self, length(self))
    else
        tv = TransientVector{T}()
        for el in self
            push!(tv, el)
        end
        persist!(tv)
    end
end

Base.start(pv::PersistentVector) = 1
Base.done(pv::PersistentVector, i::Int) = i > pv.length
Base.next(pv::PersistentVector, i::Int) = (pv[i], i+1)

function Base.map{T}(f::Function, pv::PersistentVector{T})
    tv = TransientVector{T}()
    for el::T in pv
        push!(tv, f(el))
    end
    persist!(tv)
end

function Base.hash{T}(pv::PersistentVector{T})
    h = hash(length(pv))
    for el::T in pv
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

Base.show{T}(io::IO, pv::PersistentVector{T}) = print_vec(io, pv, "Persistent{$T}")
Base.show{T}(io::IO, tv::TransientVector{T}) = print_vec(io, tv, "Transient{$T}")
