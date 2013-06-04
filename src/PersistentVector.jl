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

arrayof(    node::DenseNode) = node.arr
shift(      node::DenseNode) = node.shift
maxlength(  node::DenseNode) = node.maxlength
Base.length(node::DenseNode) = node.length

arrayof(    leaf::DenseLeaf) = leaf.arr
shift(          ::DenseLeaf) = shiftby
maxlength(  leaf::DenseLeaf) = trielen
Base.length(leaf::DenseLeaf) = length(arrayof(leaf))

promoted{T}(node::DenseBitmappedTrie{T}) =
    DenseNode{T}(DenseBitmappedTrie{T}[node],
                 shift(node) + shiftby,
                 length(node),
                 maxlength(node) * trielen)

demoted{T}(node::DenseNode{T}) =
    shift(node) == shiftby * 2 ?
    DenseLeaf{T}(T[]) :
    DenseNode{T}(DenseBitmappedTrie{T}[],
                 shift(node) - shiftby,
                 0,
                 int(maxlength(node) / trielen))

witharr{T}(node::DenseNode{T}, arr::Array) = witharr(node, arr, 0)
witharr{T}(node::DenseNode{T}, arr::Array, lenshift::Int) =
    DenseNode{T}(arr, shift(node), length(node) + lenshift, maxlength(node))

witharr{T}(leaf::DenseLeaf{T}, arr::Array) = DenseLeaf{T}(arr)

function append(leaf::DenseLeaf, el)
    if length(leaf) < maxlength(leaf)
        newarr = copy_to_len(arrayof(leaf), 1 + length(leaf))
        newarr[end] = el
        witharr(leaf, newarr)
    else
        append(promoted(leaf), el)
    end
end
function append{T}(node::DenseNode{T}, el)
    if length(node) == 0
        child = append(demoted(node), el)
        witharr(node, DenseBitmappedTrie{T}[child], 1)
    elseif length(node) < maxlength(node)
        if length(arrayof(node)[end]) == maxlength(arrayof(node)[end])
            newarr = copy_to_len(arrayof(node), 1 + length(arrayof(node)))
            newarr[end] = append(demoted(node), el)
            witharr(node, newarr, 1)
        else
            newarr = arrayof(node)[:]
            newarr[end] = append(newarr[end], el)
            witharr(node, newarr, 1)
        end
    else
        append(promoted(node), el)
    end
end
push = append

Base.getindex(leaf::DenseLeaf, i::Int) = arrayof(leaf)[mask(leaf, i)]
Base.getindex(node::DenseNode, i::Int) = arrayof(node)[mask(node, i)][i]

function assoc{T}(leaf::DenseLeaf{T}, i::Int, el)
    newarr = arrayof(leaf)[:]
    newarr[mask(leaf, i)] = el
    DenseLeaf{T}(newarr)
end
function assoc(node::DenseNode, i::Int, el)
    newarr = arrayof(node)[:]
    idx = mask(node, i)
    newarr[idx] = assoc(newarr[idx], i, el)
    witharr(node, newarr)
end

peek(bt::DenseBitmappedTrie) = bt[end]

# Pop is usually destructive, but that doesn't make sense for an immutable
# structure, so `pop` is defined to return a Trie without its last
# element. Use `peek` to access the last element.
#
pop(leaf::DenseLeaf) = witharr(leaf, arrayof(leaf)[1:end-1])
function pop(node::DenseNode)
    newarr = arrayof(node)[:]
    newarr[end] = pop(newarr[end])
    witharr(node, newarr, -1)
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
