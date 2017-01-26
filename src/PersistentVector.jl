# Persistent Vectors
# ==================

immutable PersistentVector{T} <: AbstractArray{T,1}
    trie::DenseBitmappedTrie{Vector{T}}
    tail::Vector{T}
    length::Int

    PersistentVector(trie::DenseBitmappedTrie, tail, length::Int) =
        new(trie, tail, length)
    PersistentVector() = new(DenseLeaf{Vector{T}}(), T[], 0)
    function PersistentVector(arr)
        if length(arr) <= trielen
            new(DenseLeaf{Vector{T}}(), arr, length(arr))
        else
            append(new(DenseLeaf{Vector{T}}(), T[], 0), arr)
        end
    end
end
PersistentVector() = PersistentVector{Any}()
PersistentVector(itr) = PersistentVector{eltype(itr)}(itr)

mask(i::Int) = ((i - 1) & (trielen - 1)) + 1

function boundscheck!(v::PersistentVector, i::Int)
    0 < i <= v.length || error(BoundsError(), " :: Index $i out of bounds ($(v.length))")
end

Base.size(   v::PersistentVector) = v.length
Base.length( v::PersistentVector) = v.length
Base.isempty(v::PersistentVector) = length(v) == 0
Base.endof(  v::PersistentVector) = length(v)

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

function push{T}(v::PersistentVector{T}, el)
    if length(v.tail) < trielen
        newtail = copy_to_len(v.tail, 1 + length(v.tail))
        newtail[end] = el
        PersistentVector{T}(v.trie, newtail, 1 + v.length)
    else
        # T[el] will give an error when T is an tuple type in v0.3
        # workaround:
        arr = Array{T,1}(1)
        arr[1] = convert(T, el)
        PersistentVector{T}(append(v.trie, v.tail), arr, 1 + v.length)
    end
end
append{T}(v::PersistentVector{T}, itr) = foldl(push, v, itr)

function assoc{T}(v::PersistentVector{T}, i::Int, el)
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

function pop{T}(v::PersistentVector{T})
    if isempty(v.tail)
        newtail = peek(v.trie)[1:end-1]
        PersistentVector{T}(pop(v.trie), newtail, v.length - 1)
    else
        newtail = v.tail[1:end-1]
        PersistentVector{T}(v.trie, newtail, v.length - 1)
    end
end

immutable ItrState{T}
    index::Int
    leaf::Vector{T}
end

Base.start{T}(v::PersistentVector{T}) = ItrState(1, v.length <= 32 ? v.tail : v.trie[1])
Base.done{T}(v::PersistentVector{T}, state::ItrState{T}) = state.index > v.length

function Base.next{T}(v::PersistentVector{T}, state::ItrState{T})
    i, leaf = state.index, state.leaf
    m = mask(i)
    value = leaf[m]
    i += 1
    if m == 32
        leaf = i > v.length - length(v.tail) ? v.tail : v.trie[i]
    end
    return value, ItrState(i, leaf)
end

function Base.map{T}(f::Function, pv::PersistentVector{T})
    if length(pv) == 0 return PersistentVector{T}() end

    first = f(pv[1])
    v = PersistentVector{typeof(first)}([first])
    for i = 2:length(pv)
        v = append(v, f(pv[i]))
    end
    v
end

function Base.filter{T}(f::Function, pv::PersistentVector{T})
    v = PersistentVector{T}()
    for el in pv
        if f(el)
            v = append(v, el)
        end
    end
    v
end

function Base.hash{T}(pv::PersistentVector{T})
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

 Base.show{T}(io::IO, ::MIME"text/plain", pv::PersistentVector{T}) =
    print_vec(io, pv, "Persistent{$T}")
