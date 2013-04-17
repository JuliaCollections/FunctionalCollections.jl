abstract BitmappedVector

immutable PersistentVector{T} <: BitmappedVector
    trie::BitmappedTrie
    tail::Array{T}
    length::Int

    PersistentVector(trie::BitmappedTrie, tail::Array{T}, length::Int) =
        new(trie, tail, length)
    PersistentVector() = new(Leaf{Array{T, 1}}(), T[], 0)
end

mask(i::Int) = ((i - 1) & (trielen - 1)) + 1

boundscheck!(v::BitmappedVector, i::Int) =
    0 < i <= v.length || error(BoundsError(), " :: Index $i out of bounds ($(v.length))")

Base.length(v::BitmappedVector) = v.length
Base.endof(v::BitmappedVector) = v.length

import Base.==
==(v1::BitmappedVector, v2::BitmappedVector) = v1.tail == v2.tail && v1.trie == v2.trie

function Base.getindex(v::BitmappedVector, i::Int)
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        v.tail[mask(i)]
    else
        v.trie[i][mask(i)]
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
        newtail[mask(i)] = el
        PersistentVector{T}(v.trie, newtail, v.length)
    else
        newnode = v.trie[i][1:end]
        newnode[mask(i)] = el
        PersistentVector{T}(update(v.trie, i, newnode), v.tail, v.length)
    end
end

function pop{T}(v::PersistentVector{T})
    if isempty(v.tail)
        newtail = peek(v.trie)[1:end-1]
        PersistentVector{T}(pop(v.trie), newtail, v.length - 1)
    else
        newtail = v.tail[1:end-1]
        PersistentVector{T}(v.trie, newtail, v.length - 1)
    end
end

function PersistentVector{T}(self::Array{T})
    if length(self) <= trielen
        PersistentVector{T}(Leaf{Array{T, 1}}(), self, length(self))
    else
        v = PersistentVector{T}()
        for el in self
            v = append(v, el)
        end
        v
    end
end

# Stefan and I thought this version might be faster, but it's not. (For now.)
#
# Base.start{T}(v::PersistentVector{T}) = (1, v.length <= 32 ? v.tail : v.trie[1])
# Base.done{T}(v::PersistentVector{T}, state) = state[1] > v.length
# function Base.next{T}(v::PersistentVector{T}, state)
#     i, leaf = state
#     m = mask(i)
#     value = leaf[m]
#     i += 1
#     if m == 32
#         leaf = i > v.length - length(v.tail) ? v.tail : v.trie[i]
#     end
#     return value, (i, leaf)
# end

Base.start(v::PersistentVector) = 1
Base.done(v::PersistentVector, i::Int) = i > length(v)
Base.next(v::PersistentVector, i::Int) = (v[i], i + 1)

function Base.map{T}(f::Function, pv::PersistentVector{T})
    v = PersistentVector{T}()
    for el in pv
        v = append(v, f(el))
    end
    v
end

function Base.hash{T}(pv::PersistentVector{T})
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

Base.show{T}(io::IO, pv::PersistentVector{T}) = print_vec(io, pv, "Persistent{$T}")
