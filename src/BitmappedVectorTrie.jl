# `shiftby` is equal to the number of bits required to represent index information
# for one level of the BitmappedTrie.
#
# Here, `shiftby` is 5, which means that the BitmappedTrie Arrays will be length 32.
const shiftby = 5
const trielen = 2^shiftby

abstract BitmappedTrie{T}

immutable Node{T} <: BitmappedTrie{T}
    self::Array{BitmappedTrie{T}, 1}
    shift::Int
    length::Int
    maxlength::Int
end
Node{T}() = Node{T}(BitmappedTrie{T}[], shiftby*2, 0, trielen)

immutable Leaf{T} <: BitmappedTrie{T}
    self::Array{T, 1}

    Leaf(self::Array) = new(self)
    Leaf() = new(T[])
end

shift(n::Node) = n.shift
maxlength(n::Node) = n.maxlength
Base.length(n::Node) = n.length

shift(::Leaf) = 5
maxlength(l::Leaf) = trielen
Base.length(l::Leaf) = length(l.self)

mask(t::BitmappedTrie, i::Int) = (((i - 1) >>> shift(t)) & (trielen - 1)) + 1

Base.endof(t::BitmappedTrie) = length(t)

function Base.isequal(t1::BitmappedTrie, t2::BitmappedTrie)
    length(t1)    == length(t2)    &&
    shift(t1)     == shift(t2)     &&
    maxlength(t1) == maxlength(t2) &&
    t1.self       == t2.self
end

promoted{T}(n::BitmappedTrie{T}) =
    Node{T}(BitmappedTrie{T}[n], shift(n) + shiftby, length(n), maxlength(n) * trielen)

demoted{T}(n::Node{T}) =
    if shift(n) == shiftby * 2
        Leaf{T}(T[])
    else
        Node{T}(BitmappedTrie{T}[], shift(n) - shiftby, 0, int(maxlength(n) / trielen))
    end

withself{T}(n::Node{T}, self::Array) = withself(n, self, 0)
withself{T}(n::Node{T}, self::Array, lenshift::Int) =
    Node{T}(self, shift(n), length(n) + lenshift, maxlength(n))

withself{T}(l::Leaf{T}, self::Array) = Leaf{T}(self)

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

function append{T}(l::Leaf{T}, el::T)
    if length(l) < maxlength(l)
        newself = copy_to_len(l.self, 1 + length(l))
        newself[end] = el
        withself(l, newself)
    else
        append(promoted(l), el)
    end
end
function append{T}(n::Node{T}, el::T)
    if length(n) == 0
        child = append(demoted(n), el)
        withself(n, BitmappedTrie{T}[child], 1)
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

Base.getindex(l::Leaf, i::Int) = l.self[mask(l, i)]
Base.getindex(n::Node, i::Int) = n.self[mask(n, i)][i]

function update{T}(l::Leaf{T}, i::Int, el::T)
    newself = l.self[:]
    newself[mask(l, i)] = el
    Leaf{T}(newself)
end
function update{T}(n::Node{T}, i::Int, el::T)
    newself = n.self[:]
    idx = mask(n, i)
    newself[idx] = update(newself[idx], i, el)
    withself(n, newself)
end

peek(bt::BitmappedTrie) = bt[end]

# Pop is usually destructive, but that doesn't make sense for an immutable
# structure, so `pop` is defined to return a Trie without its last
# element. Use `peek` to access the last element.
#
pop(l::Leaf) = withself(l, l.self[1:end-1])
function pop(n::Node)
    newself = n.self[:]
    newself[end] = pop(newself[end])
    withself(n, newself, -1)
end
