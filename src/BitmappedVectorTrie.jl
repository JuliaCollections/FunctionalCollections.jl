# `shiftby` is equal to the number of bits required to represent index information
# for one level of the BitmappedTrie.
#
# Here, `shiftby` is 5, which means that the BitmappedTrie Arrays will be length 32.
const shiftby = 5
const trielen = 2^shiftby

# Copy elements from one Array to another, up to `n` elements.
#
function copy_to{T}(from::Array{T}, to::Array{T}, n::Int)
    for i=1:n
        to[i] = from[i]
    end
    to
end

# Copies elements from one Array to another of size `len`.
#
copy_to_len{T}(from::Array{T}, len::Int) =
    copy_to(from, Array(T, len), min(len, length(from)))

abstract BitmappedTrie{T}
abstract DenseBitmappedTrie{T} <: BitmappedTrie{T}
abstract SparseBitmappedTrie{T} <: BitmappedTrie{T}

# Bitmapped Tries
#
immutable DenseNode{T} <: DenseBitmappedTrie{T}
    self::Vector{DenseBitmappedTrie{T}}
    shift::Int
    length::Int
    maxlength::Int
end
DenseNode{T}() = DenseNode{T}(DenseBitmappedTrie{T}[], shiftby*2, 0, trielen)

immutable DenseLeaf{T} <: DenseBitmappedTrie{T}
    self::Vector{T}

    DenseLeaf(self::Vector) = new(self)
    DenseLeaf() = new(T[])
end

immutable SparseNode{T} <: SparseBitmappedTrie{T}
    self::Vector{SparseBitmappedTrie{T}}
    shift::Int
    length::Int
    maxlength::Int
    bitmap::Int
end
SparseNode(T::Type) = SparseNode{T}(SparseBitmappedTrie{T}[], shiftby*7, 0, trielen^7, 0)

immutable SparseLeaf{T} <: SparseBitmappedTrie{T}
    self::Vector{T}
    bitmap::Int

    SparseLeaf(self::Vector, bitmap::Int) = new(self, bitmap)
    SparseLeaf() = new(T[], 0)
end

shift(n::Union(DenseNode, SparseNode)) = n.shift
maxlength(n::Union(DenseNode, SparseNode)) = n.maxlength
Base.length(n::Union(DenseNode, SparseNode)) = n.length

maxlength(l::Union(DenseLeaf, SparseLeaf)) = trielen
Base.length(l::Union(DenseLeaf, SparseLeaf)) = length(l.self)

shift(::DenseLeaf) = 5
shift(::SparseLeaf) = 0

mask(t::BitmappedTrie, i::Int) = (((i - 1) >>> shift(t)) & (trielen - 1)) + 1

Base.endof(t::BitmappedTrie) = length(t)

function Base.isequal(t1::BitmappedTrie, t2::BitmappedTrie)
    length(t1)    == length(t2)    &&
    shift(t1)     == shift(t2)     &&
    maxlength(t1) == maxlength(t2) &&
    t1.self       == t2.self
end

# Dense Bitmapped Tries
# =====================

promoted{T}(n::DenseBitmappedTrie{T}) =
    DenseNode{T}(DenseBitmappedTrie{T}[n], shift(n) + shiftby, length(n), maxlength(n) * trielen)

demoted{T}(n::DenseNode{T}) =
    if shift(n) == shiftby * 2
        DenseLeaf{T}(T[])
    else
        DenseNode{T}(DenseBitmappedTrie{T}[], shift(n) - shiftby, 0, int(maxlength(n) / trielen))
    end

withself{T}(n::DenseNode{T}, self::Array) = withself(n, self, 0)
withself{T}(n::DenseNode{T}, self::Array, lenshift::Int) =
    DenseNode{T}(self, shift(n), length(n) + lenshift, maxlength(n))

withself{T}(l::DenseLeaf{T}, self::Array) = DenseLeaf{T}(self)

function append{T}(l::DenseLeaf{T}, el::T)
    if length(l) < maxlength(l)
        newself = copy_to_len(l.self, 1 + length(l))
        newself[end] = el
        withself(l, newself)
    else
        append(promoted(l), el)
    end
end
function append{T}(n::DenseNode{T}, el::T)
    if length(n) == 0
        child = append(demoted(n), el)
        withself(n, DenseBitmappedTrie{T}[child], 1)
    elseif length(n) < maxlength(n)
        if length(n.self[end]) == maxlength(n.self[end])
            newself = copy_to_len(n.self, 1 + length(n.self))
            newself[end] = append(demoted(n), el)
            withself(n, newself, 1)
        else
            newself = n.self[:]
            newself[end] = append(newself[end], el)
            withself(n, newself, 1)
        end
    else
        append(promoted(n), el)
    end
end
push = append

Base.getindex(l::DenseLeaf, i::Int) = l.self[mask(l, i)]
Base.getindex(n::DenseNode, i::Int) = n.self[mask(n, i)][i]

function update{T}(l::DenseLeaf{T}, i::Int, el::T)
    newself = l.self[:]
    newself[mask(l, i)] = el
    DenseLeaf{T}(newself)
end
function update{T}(n::DenseNode{T}, i::Int, el::T)
    newself = n.self[:]
    idx = mask(n, i)
    newself[idx] = update(newself[idx], i, el)
    withself(n, newself)
end

peek(bt::DenseBitmappedTrie) = bt[end]

# Pop is usually destructive, but that doesn't make sense for an immutable
# structure, so `pop` is defined to return a Trie without its last
# element. Use `peek` to access the last element.
#
pop(l::DenseLeaf) = withself(l, l.self[1:end-1])
function pop(n::DenseNode)
    newself = n.self[:]
    newself[end] = pop(newself[end])
    withself(n, newself, -1)
end

# Sparse Bitmapped Tries
# ======================

function demoted{T}(n::SparseNode{T})
    if shift(n) == shiftby
        SparseLeaf{T}(T[], 0)
    else
        SparseNode{T}(SparseBitmappedTrie{T}[], shift(n) - shiftby, 0, int(maxlength(n) / trielen), 0)
    end
end

bitpos(t::SparseBitmappedTrie, i::Int) = 1 << (mask(t, i) - 1)
hasindex(t::SparseBitmappedTrie, i::Int) =
    t.bitmap & bitpos(t, i) != 0
index(t::SparseBitmappedTrie, i::Int) =
    1 + count_ones(t.bitmap & (bitpos(t, i) - 1))

function update{T}(l::SparseLeaf{T}, i::Int, el::T)
    hasi = hasindex(l, i)
    bitmap = bitpos(l, i) | l.bitmap
    idx = index(l, i)
    if hasi
        newself = l.self[:]
        newself[idx] = el
    else
        newself = vcat(l.self[1:idx-1], [el], l.self[idx:end])
    end
    (SparseLeaf{T}(newself, bitmap), !hasi)
end
function update{T}(n::SparseNode{T}, i::Int, el::T)
    bitmap = bitpos(n, i) | n.bitmap
    idx = index(n, i)
    if hasindex(n, i)
        newself = n.self[:]
        updated, inc = update(newself[idx], i, el)
        newself[idx] = updated
    else
        child, inc = update(demoted(n), i, el)
        newself = vcat(n.self[1:idx-1], [child], n.self[idx:end])
    end
    (SparseNode{T}(newself, n.shift, inc ? n.length + 1 : n.length, n.maxlength, bitmap), inc)
end

Base.get(n::SparseLeaf, i::Int, default) =
    hasindex(n, i) ? n.self[index(n, i)] : default
Base.get(n::SparseNode, i::Int, default) =
    hasindex(n, i) ? get(n.self[index(n, i)], i, default) : default

function Base.start(t::SparseBitmappedTrie)
    t.length == 0 && return true
    ones(Int, 1 + int(t.shift / shiftby))
end

function directindex(t::SparseBitmappedTrie, v::Vector{Int})
    isempty(v) && return t.self
    local node = t.self
    for i=v
        node = node[i]
        node = isa(node, SparseBitmappedTrie) ? node.self : node
    end
    node
end

Base.done(t::SparseBitmappedTrie, state) = state == true

function Base.next(t::SparseBitmappedTrie, state::Vector{Int})
    item = directindex(t, state)
    while true
        index = pop!(state)
        node = directindex(t, state)
        if length(node) > index
            push!(state, index + 1)
            return item, vcat(state, ones(Int, 1 + int(t.shift / shiftby) - length(state)))
        elseif is(node, t.self)
            return item, true
        end
    end
end
