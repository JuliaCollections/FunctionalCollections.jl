module PersistentVectors

export PersistentVector,
       append, push,
       # Base.getindex,
       update,
       peek,
       pop

# `shiftby` is equal to the number of bits required to represent index information
# for one level of the BitmappedTrie.
#
# Here, `shiftby` is 5, which means that the BitmappedTrie Arrays will be length 32.
const shiftby = 5
const trielen = 2^shiftby
const andval  = trielen - 1

immutable BitmappedTrie
    self::Array
    shift::Int
    length::Int
    maxlength::Int
end
BitmappedTrie() = BitmappedTrie(Any[], 0, 0, trielen)

Base.length(bt::BitmappedTrie) = bt.length
Base.endof(bt::BitmappedTrie) = bt.length

similar(bt::BitmappedTrie) =
    BitmappedTrie(Any[], bt.shift, 0, bt.maxlength)

promoted(bt::BitmappedTrie) =
    BitmappedTrie(Any[bt], bt.shift + shiftby, bt.length, bt.maxlength * trielen)

demoted(bt::BitmappedTrie) =
    BitmappedTrie(Any[], bt.shift - shiftby, 0, int(bt.maxlength / trielen))

withself(bt::BitmappedTrie, self::Array, lenshift::Int) =
    BitmappedTrie(self, bt.shift, length(bt) + lenshift, bt.maxlength)

# Copy elements from one Array to another, up to `n` elements.
#
function copy_to(from::Array, to::Array, n::Int)
    for i=1:n
        to[i] = from[i]
    end
    to
end

# Copies elements from one Array to another of size `len`.
#
copy_to_len{T}(from::Array{T}, len::Int) =
    copy_to(from, Array(T, len), min(len, length(from)))

function append(bt::BitmappedTrie, el)
    if bt.shift == 0
        if length(bt) < trielen
            newself = copy_to_len(bt.self, 1 + length(bt))
            newself[end] = el
            withself(bt, newself, 1)
        else
            append(promoted(bt), el)
        end
    else
        if length(bt) == 0
            withself(bt, Any[append(demoted(bt), el)], 1)
        elseif length(bt) < bt.maxlength
            if length(bt.self[end]) == bt.self[end].maxlength
                newself = copy_to_len(bt.self, 1 + length(bt.self))
                newself[end] = append(demoted(bt), el)
                withself(bt, newself, 1)
            else
                newself = bt.self[1:end]
                newself[end] = append(bt.self[end], el)
                withself(bt, newself, 1)
            end
        else
            append(promoted(bt), el)
        end
    end
end
push = append

function get(bt::BitmappedTrie, i::Int)
    # Decrement i so that the bitwise math works out. It will be incremented
    # before indexing into Arrays.
    i -= 1
    if bt.shift == 0
        bt.self[(i & andval) + 1]
    else
        get(bt.self[((i >>> bt.shift) & andval) + 1], i + 1)
    end
end

function Base.getindex(bt::BitmappedTrie, i::Int)
    i <= length(bt) || error(BoundsError())
    get(bt, i)
end

function update(bt::BitmappedTrie, i::Int, element)
    i -= 1
    if bt.shift == 0
        newself = bt.self[1:end]
        newself[(i & andval) + 1] = element
    else
        newself = bt.self[1:end]
        idx = ((i >>> bt.shift) & andval) + 1
        newself[idx] = update(newself[idx], i + 1, element)
    end
    BitmappedTrie(newself, bt.shift, bt.length, bt.maxlength)
end

peek(bt::BitmappedTrie) = bt[end]

# Pop is usually destructive, but that doesn't make sense for an immutable
# structure, so `pop` is defined to return a Trie without its last
# element. Use `peek` to access the last element.
#
function pop(bt::BitmappedTrie)
    if bt.shift == 0
        withself(bt, bt.self[1:end-1], -1)
    else
        newself = bt.self[1:end]
        newself[end] = pop(newself[end])
        withself(bt, newself, -1)
    end
end

# In this initial implementation, a PersistentVector is a BitmappedTrie. This
# may change, with the Vector becoming more of a wrapper.
#
typealias PersistentVector BitmappedTrie

function print_elements(io, pv, range)
    for i=range
        print(io, "$(pv[i]), ")
    end
end

function Base.show(io::IO, pv::PersistentVector)
    print(io, "Persistent[")
    if length(pv) < 50
        print_elements(io, pv, 1:length(pv)-1)
    else
        print_elements(io, pv, 1:25)
        print(io, "..., ")
        print_elements(io, pv, length(pv)-25:length(pv)-1)
    end
    if length(pv) >= 1
        print(io, "$(pv[end])]")
    else
        print(io, "]")
    end
end

end # module PersistentVectors
