# Persistent Vectors
# ==================

struct PersistentVector{T} <: AbstractArray{T,1}
    trie::DenseBitmappedTrie{Vector{T}}
    tail::Vector{T}
    length::Int
end
PersistentVector{T}() where {T} =
    PersistentVector{T}(DenseLeaf{Vector{T}}(), T[], 0)
function PersistentVector{T}(arr) where T
    if length(arr) <= trielen
        PersistentVector{T}(DenseLeaf{Vector{T}}(), arr, length(arr))
    else
        append(PersistentVector{T}(DenseLeaf{Vector{T}}(), T[], 0), arr)
    end
end
PersistentVector() = PersistentVector{Any}()
PersistentVector(itr) = PersistentVector{eltype(itr)}(itr)

mask(i::Int) = ((i - 1) & (trielen - 1)) + 1

function boundscheck!(v::PersistentVector, i::Int)
    0 < i <= v.length || error(BoundsError(), " :: Index $i out of bounds ($(v.length))")
end

Base.size(   v::PersistentVector) = (v.length,)
Base.length( v::PersistentVector) = v.length
Base.isempty(v::PersistentVector) = length(v) == 0
Base.lastindex(  v::PersistentVector) = length(v)

Base.isequal(v1::PersistentVector, v2::PersistentVector) =
    isequal(v1.tail, v2.tail) && isequal(v1.trie, v2.trie)
==(v1::PersistentVector, v2::PersistentVector) =
    v1.tail == v2.tail && v1.trie == v2.trie

function Base.getindex(v::PersistentVector, i::Int)
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        v.tail[mask(i)]
    else
        v.trie[i][mask(i)]
    end
end

peek(v::PersistentVector) = v[end]

function push(v::PersistentVector{T}, el) where T
    if length(v.tail) < trielen
        newtail = copy_to_len(v.tail, 1 + length(v.tail))
        newtail[end] = el
        PersistentVector{T}(v.trie, newtail, 1 + v.length)
    else
        # T[el] will give an error when T is an tuple type in v0.3
        # workaround:
        arr = Array{T,1}(undef, 1)
        arr[1] = convert(T, el)
        PersistentVector{T}(append(v.trie, v.tail), arr, 1 + v.length)
    end
end
append(v::PersistentVector{T}, itr) where {T} = foldl(push, itr, init=v)

function assoc(v::PersistentVector{T}, i::Int, el) where T
    boundscheck!(v, i)
    if i > v.length - length(v.tail)
        newtail = v.tail[1:end]
        newtail[mask(i)] = el
        PersistentVector{T}(v.trie, newtail, v.length)
    else
        newnode = v.trie[i][1:end]
        newnode[mask(i)] = el
        PersistentVector{T}(assoc(v.trie, i, newnode), v.tail, v.length)
    end
end

function pop(v::PersistentVector{T}) where T
    if isempty(v.tail)
        newtail = peek(v.trie)[1:end-1]
        PersistentVector{T}(pop(v.trie), newtail, v.length - 1)
    else
        newtail = v.tail[1:end-1]
        PersistentVector{T}(v.trie, newtail, v.length - 1)
    end
end

struct ItrState{T}
    index::Int
    leaf::Vector{T}
end

function Base.iterate(v::PersistentVector, state = ItrState(1, v.length <= 32 ? v.tail : v.trie[1]))
    if state.index > v.length
        return nothing
    else
        i, leaf = state.index, state.leaf
        m = mask(i)
        value = leaf[m]
        i += 1
        if m == 32
            leaf = i > v.length - length(v.tail) ? v.tail : v.trie[i]
        end
        return value, ItrState(i, leaf)
    end
end

function Base.map(f::Function, pv::PersistentVector{T}) where T
    if length(pv) == 0 return PersistentVector{T}() end

    first = f(pv[1])
    v = PersistentVector{typeof(first)}([first])
    for i = 2:length(pv)
        v = push(v, f(pv[i]))
    end
    v
end

function Base.filter(f::Function, pv::PersistentVector{T}) where T
    v = PersistentVector{T}()
    for el in pv
        if f(el)
            v = push(v, el)
        end
    end
    v
end

function Base.hash(pv::PersistentVector{T}) where T
    h = hash(length(pv))
    for el in pv
        h = Base.hash(el, h)
    end
     UInt(h)
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

 Base.show(io::IO, ::MIME"text/plain", pv::PersistentVector{T}) where {T} =
    print_vec(io, pv, "Persistent{$T}")
