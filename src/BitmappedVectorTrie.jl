# implements Tries

# `shiftby` is equal to the number of bits required to represent index information
# for one level of the BitmappedTrie.
#
# Here, `shiftby` is 5, which means that the BitmappedTrie Arrays will be length 32.
const shiftby = 5
const trielen = 2^shiftby

abstract type BitmappedTrie{T} end

# Copy elements from one Array to another, up to `n` elements.
#
function copy_to(from::Array{T}, to::Array{T}, n::Int) where {T}
    for i=1:n
        to[i] = from[i]
    end
    to
end

# Copies elements from one Array to another of size `len`.
#
copy_to_len(from::Array{T}, len::Int) where {T} =
    copy_to(from, Array{T,1}(undef, len), min(len, length(from)))

mask(t::BitmappedTrie, i::Int) = (((i - 1) >>> shift(t)) & (trielen - 1)) + 1

Base.lastindex(t::BitmappedTrie) = length(t)

Base.length(t::BitmappedTrie) =
    error("$(typeof(t)) does not implement Base.length")
shift(t::BitmappedTrie) =
    error("$(typeof(t)) does not implement FunctionalCollections.shift")
maxlength(t::BitmappedTrie) =
    error("$(typeof(t)) does not implement FunctionalCollections.maxlength")
arrayof(t::BitmappedTrie) =
    error("$(typeof(t)) does not implement FunctionalCollections.arrayof")

function Base.isequal(t1::BitmappedTrie, t2::BitmappedTrie)
    length(t1)    == length(t2)    &&
    shift(t1)     == shift(t2)     &&
    maxlength(t1) == maxlength(t2) &&
    arrayof(t1)   == arrayof(t2)
end

==(t1::BitmappedTrie, t2::BitmappedTrie) = isequal(t1, t2)


# Dense Bitmapped Tries
# =====================

abstract type DenseBitmappedTrie{T} <: BitmappedTrie{T} end

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

struct DenseNode{T} <: DenseBitmappedTrie{T}
    arr::Vector{DenseBitmappedTrie{T}}
    shift::Int
    length::Int
    maxlength::Int
end

struct DenseLeaf{T} <: DenseBitmappedTrie{T}
    arr::Vector{T}
end
DenseLeaf{T}() where {T} = DenseLeaf{T}(T[])

arrayof(    node::DenseNode) = node.arr
shift(      node::DenseNode) = node.shift
maxlength(  node::DenseNode) = node.maxlength
Base.length(node::DenseNode) = node.length

arrayof(    leaf::DenseLeaf) = leaf.arr
shift(          ::DenseLeaf) = shiftby
maxlength(  leaf::DenseLeaf) = trielen
Base.length(leaf::DenseLeaf) = length(arrayof(leaf))

function promoted(node::DenseBitmappedTrie{T}) where T
    DenseNode{T}(DenseBitmappedTrie{T}[node],
                 shift(node) + shiftby,
                 length(node),
                 maxlength(node) * trielen)
end

function demoted(node::DenseNode{T}) where T
    if shift(node) == shiftby * 2
        DenseLeaf{T}(T[])
    else
        DenseNode{T}(DenseBitmappedTrie{T}[],
                     shift(node) - shiftby,
                     0,
                     round(Int, maxlength(node) / trielen))
    end
end

function witharr(node::DenseNode{T}, arr::Array, lenshift::Int=0) where T
    DenseNode{T}(arr, shift(node), length(node) + lenshift, maxlength(node))
end
witharr(leaf::DenseLeaf{T}, arr::Array) where {T} = DenseLeaf{T}(arr)

function append(leaf::DenseLeaf, el)
    if length(leaf) < maxlength(leaf)
        newarr = copy_to_len(arrayof(leaf), 1 + length(leaf))
        newarr[end] = el
        witharr(leaf, newarr)
    else
        append(promoted(leaf), el)
    end
end
function append(node::DenseNode{T}, el) where T
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
push(leaf::DenseLeaf, el) = append(leaf, el)
push(node::DenseNode, el) = append(node, el)

Base.getindex(leaf::DenseLeaf, i::Int) = arrayof(leaf)[mask(leaf, i)]
Base.getindex(node::DenseNode, i::Int) = arrayof(node)[mask(node, i)][i]

function assoc(leaf::DenseLeaf{T}, i::Int, el) where T
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

# Sparse Bitmapped Tries
# ======================

abstract type SparseBitmappedTrie{T} <: BitmappedTrie{T} end

struct SparseNode{T} <: SparseBitmappedTrie{T}
    arr::Vector{SparseBitmappedTrie{T}}
    shift::Int
    length::Int
    maxlength::Int
    bitmap::Int
end
SparseNode(T::Type) = SparseNode{T}(SparseBitmappedTrie{T}[], shiftby*7, 0, trielen^7, 0)

struct SparseLeaf{T} <: SparseBitmappedTrie{T}
    arr::Vector{T}
    bitmap::Int
end
SparseLeaf{T}() where {T} = SparseLeaf{T}(T[], 0)

arrayof(    n::SparseNode) = n.arr
shift(      n::SparseNode) = n.shift
maxlength(  n::SparseNode) = n.maxlength
Base.length(n::SparseNode) = n.length

arrayof(    l::SparseLeaf) = l.arr
shift(       ::SparseLeaf) = 0
maxlength(  l::SparseLeaf) = trielen
Base.length(l::SparseLeaf) = length(arrayof(l))

function demoted(n::SparseNode{T}) where T
    shift(n) == shiftby ?
    SparseLeaf{T}(T[], 0) :
    SparseNode{T}(SparseBitmappedTrie{T}[],
                  shift(n) - shiftby,
                  0,
                  round(Int, maxlength(n) / trielen), 0)
end

bitpos(  t::SparseBitmappedTrie, i::Int) = 1 << (mask(t, i) - 1)
hasindex(t::SparseBitmappedTrie, i::Int) = t.bitmap & bitpos(t, i) != 0
index(   t::SparseBitmappedTrie, i::Int) =
    1 + count_ones(t.bitmap & (bitpos(t, i) - 1))

function update(l::SparseLeaf{T}, i::Int, el::T) where T
    hasi = hasindex(l, i)
    bitmap = bitpos(l, i) | l.bitmap
    idx = index(l, i)
    if hasi
        newarr = arrayof(l)[:]
        newarr[idx] = el
    else
        newarr = vcat(arrayof(l)[1:idx-1], [el], arrayof(l)[idx:end])
    end
    (SparseLeaf{T}(newarr, bitmap), !hasi)
end
function update(n::SparseNode{T}, i::Int, el::T) where T
    bitmap = bitpos(n, i) | n.bitmap
    idx = index(n, i)
    if hasindex(n, i)
        newarr = arrayof(n)[:]
        updated, inc = update(newarr[idx], i, el)
        newarr[idx] = updated
    else
        child, inc = update(demoted(n), i, el)
        newarr = vcat(arrayof(n)[1:idx-1], [child], arrayof(n)[idx:end])
    end
    (SparseNode{T}(newarr,
                   n.shift,
                   inc ? n.length + 1 : n.length,
                   n.maxlength, bitmap),
     inc)
end

Base.get(n::SparseLeaf, i::Int, default) =
    hasindex(n, i) ? arrayof(n)[index(n, i)] : default
Base.get(n::SparseNode, i::Int, default) =
    hasindex(n, i) ? get(arrayof(n)[index(n, i)], i, default) : default

function initial_state(t::SparseBitmappedTrie)
    t.length == 0 && return Int[]
    ones(Int, 1 + round(Int, t.shift / shiftby))
end

function Base.iterate(t::SparseBitmappedTrie, state = initial_state(t))
    if isempty(state)
        return nothing
    else
        item = directindex(t, state)
        while true
            index = pop!(state)
            node = directindex(t, state)
            if length(node) > index
                push!(state, index + 1)
                return item, vcat(state, ones(Int, 1 + round(Int, t.shift / shiftby) -
                                                   length(state)))
            elseif node === arrayof(t)
                return item, Int[]
            end
        end
    end
end

function directindex(t::SparseBitmappedTrie, v::Vector{Int})
    isempty(v) && return arrayof(t)
    local node = arrayof(t)
    for i=v
        node = node[i]
        node = isa(node, SparseBitmappedTrie) ? arrayof(node) : node
    end
    node
end
