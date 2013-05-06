# Dense Bitmapped Tries
# =====================

abstract DenseBitmappedTrie{T} <: BitmappedTrie{T}

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

shift(      n::DenseNode) = n.shift
maxlength(  n::DenseNode) = n.maxlength
Base.length(n::DenseNode) = n.length

shift(       ::DenseLeaf) = 5
maxlength(  l::DenseLeaf) = trielen
Base.length(l::DenseLeaf) = length(l.self)

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

function PersistentVector{T}(self::Vector{T})
    if length(self) <= trielen
        PersistentVector{T}(DenseLeaf{Vector{T}}(), self, length(self))
    else
        v = PersistentVector{T}()
        for el in self
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
