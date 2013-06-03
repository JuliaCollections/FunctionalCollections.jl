# Dense Bitmapped Tries
# =====================

abstract DenseBitmappedTrie{T} <: BitmappedTrie{T}

# Why is the shift value of a DenseLeaf 5 instead of 0, and why does
# the shift value of a DenseNode start at 10?
#
# The PersistentVector implements a "tail" optimization, where it
# inserts appended elements into a tail array until that array is 32
# elements long, only then inserting it into the actual bitmapped
# vector trie. This significantly increases the performance of
# operations that touch the very end of the vector (last, append, pop,
# etc.) because you don't have to traverse the trie.
#
# However, it adds a small amount of complexity to the implementation;
# when you query the trie, you now get back a length-32 array instead
# of the actual element. This is why the DenseLeaf has a shift value
# of 5: it leaves an "extra" 5 bits for the PersistentVector to use to
# index into the array returned from the trie. (This also means that a
# DenseNode has to start at shiftby*2.)

immutable DenseNode{T} <: DenseBitmappedTrie{T}
    arr::Vector{DenseBitmappedTrie{T}}
    shift::Int
    length::Int
    maxlength::Int
end
DenseNode{T}() = DenseNode{T}(DenseBitmappedTrie{T}[], shiftby*2, 0, trielen)

immutable DenseLeaf{T} <: DenseBitmappedTrie{T}
    arr::Vector{T}

    DenseLeaf(arr::Vector) = new(arr)
    DenseLeaf() = new(T[])
end

arrayof(    n::DenseNode) = n.arr
shift(      n::DenseNode) = n.shift
maxlength(  n::DenseNode) = n.maxlength
Base.length(n::DenseNode) = n.length

arrayof(    l::DenseLeaf) = l.arr
shift(       ::DenseLeaf) = 5
maxlength(  l::DenseLeaf) = trielen
Base.length(l::DenseLeaf) = length(arrayof(l))

promoted{T}(n::DenseBitmappedTrie{T}) =
    DenseNode{T}(DenseBitmappedTrie{T}[n],
                 shift(n) + shiftby,
                 length(n),
                 maxlength(n) * trielen)

function demoted{T}(n::DenseNode{T})
    shift(n) == shiftby * 2 ?
    DenseLeaf{T}(T[]) :
    DenseNode{T}(DenseBitmappedTrie{T}[],
                 shift(n) - shiftby,
                 0,
                 int(maxlength(n) / trielen))
end

witharr{T}(n::DenseNode{T}, arr::Array) = witharr(n, arr, 0)
witharr{T}(n::DenseNode{T}, arr::Array, lenshift::Int) =
    DenseNode{T}(arr, shift(n), length(n) + lenshift, maxlength(n))

witharr{T}(l::DenseLeaf{T}, arr::Array) = DenseLeaf{T}(arr)

function append{T}(l::DenseLeaf{T}, el::T)
    if length(l) < maxlength(l)
        newarr = copy_to_len(arrayof(l), 1 + length(l))
        newarr[end] = el
        witharr(l, newarr)
    else
        append(promoted(l), el)
    end
end
function append{T}(n::DenseNode{T}, el::T)
    if length(n) == 0
        child = append(demoted(n), el)
        witharr(n, DenseBitmappedTrie{T}[child], 1)
    elseif length(n) < maxlength(n)
        if length(arrayof(n)[end]) == maxlength(arrayof(n)[end])
            newarr = copy_to_len(arrayof(n), 1 + length(arrayof(n)))
            newarr[end] = append(demoted(n), el)
            witharr(n, newarr, 1)
        else
            newarr = arrayof(n)[:]
            newarr[end] = append(newarr[end], el)
            witharr(n, newarr, 1)
        end
    else
        append(promoted(n), el)
    end
end
push = append

Base.getindex(l::DenseLeaf, i::Int) = arrayof(l)[mask(l, i)]
Base.getindex(n::DenseNode, i::Int) = arrayof(n)[mask(n, i)][i]

function update{T}(l::DenseLeaf{T}, i::Int, el::T)
    newarr = arrayof(l)[:]
    newarr[mask(l, i)] = el
    DenseLeaf{T}(newarr)
end
function update{T}(n::DenseNode{T}, i::Int, el::T)
    newarr = arrayof(n)[:]
    idx = mask(n, i)
    newarr[idx] = update(newarr[idx], i, el)
    witharr(n, newarr)
end

peek(bt::DenseBitmappedTrie) = bt[end]

# Pop is usually destructive, but that doesn't make sense for an immutable
# structure, so `pop` is defined to return a Trie without its last
# element. Use `peek` to access the last element.
#
pop(l::DenseLeaf) = witharr(l, arrayof(l)[1:end-1])
function pop(n::DenseNode)
    newarr = arrayof(n)[:]
    newarr[end] = pop(newarr[end])
    witharr(n, newarr, -1)
end

# Persistent Vectors
# ==================

immutable PersistentVector{T} <: AbstractArray{T}
    trie::DenseBitmappedTrie{Vector{T}}
    tail::Vector{T}
    length::Int

    PersistentVector(trie::DenseBitmappedTrie, tail::Vector{T}, length::Int) =
        new(trie, tail, length)
    PersistentVector() = new(DenseLeaf{Vector{T}}(), T[], 0)
end
PersistentVector() = PersistentVector{Any}()

mask(i::Int) = ((i - 1) & (trielen - 1)) + 1

boundscheck!(v::PersistentVector, i::Int) =
    0 < i <= v.length || error(BoundsError(),
                               " :: Index $i out of bounds ($(v.length))")

Base.size(   v::PersistentVector) = v.length
Base.length( v::PersistentVector) = v.length
Base.isempty(v::PersistentVector) = length(v) == 0
Base.endof(  v::PersistentVector) = length(v)

Base.isequal(v1::PersistentVector, v2::PersistentVector) =
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

function append{T}(v::PersistentVector{T}, el)
    if length(v.tail) < trielen
        newtail = copy_to_len(v.tail, 1 + length(v.tail))
        newtail[end] = el
        PersistentVector{T}(v.trie, newtail, 1 + v.length)
    else
        PersistentVector{T}(append(v.trie, v.tail), T[el], 1 + v.length)
    end
end

function update{T}(v::PersistentVector{T}, i::Int, el)
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

function PersistentVector{T}(arr::Vector{T})
    if length(arr) <= trielen
        PersistentVector{T}(DenseLeaf{Vector{T}}(), arr, length(arr))
    else
        v = PersistentVector{T}()
        for el in arr
            v = append(v, el)
        end
        v
    end
end

immutable ItrState{T}
    index::Int
    leaf::Vector{T}
end

Base.start{T}(v::PersistentVector{T}) = ItrState(1, v.length <= 32 ? v.tail : v.trie[1])
Base.done{T}(v::PersistentVector{T}, state::ItrState{T}) = state.index > v.length
function Base.next{T}(v::PersistentVector{T}, state::ItrState{T})
    i = state.index
    leaf = state.leaf
    m = mask(i)
    value = leaf[m]
    i += 1
    if m == 32
        leaf = i > v.length - length(v.tail) ? v.tail : v.trie[i]
    end
    return value, ItrState(i, leaf)
end

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

Base.show{T}(io::IO, pv::PersistentVector{T}) =
    print_vec(io, pv, "Persistent{$T}")
