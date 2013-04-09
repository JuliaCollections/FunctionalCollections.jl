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

type BitmappedTrie
    self::Array
    shift::Int
    length::Int
    maxlength::Int
end
BitmappedTrie() = BitmappedTrie(Any[], 0, 0, trielen)

Base.length(bt::BitmappedTrie) = bt.length
Base.endof(bt::BitmappedTrie) = bt.length

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
    # There are 6 append cases:
    #
    # `bt` is a leaf (shift == 0) and it has room to spare. Add the new element.
    #
    # `bt` is a leaf but it doesn't have room to spare. Insert it and a similar
    # Trie into a promoted Trie, and add the element to the newly created,
    # empty similar Trie.
    #
    # `bt` isn't a leaf, but it's empty. Construct a child and allow it to
    # perform the insert.
    #
    # `bt` isn't a leaf, it's not empty, but it's last child is full. Construct
    # a new child and allow it to perform the insert.
    #
    # `bt` isn't a leaf, it's not empty, and it's last child has room to spare.
    # Allow the child to insert the element.
    #
    # `bt` isn't a leaf but it doesn't have room to spare. Construct a promoted
    # Trie as if it were a leaf.
    #
    if bt.shift == 0
        if length(bt) < trielen
            newself = copy_to_len(bt.self, 1 + length(bt))
            newself[end] = el
            return BitmappedTrie(newself, bt.shift, 1 + length(bt), bt.maxlength)
        end
    else
        if length(bt) == 0
            bt2 = BitmappedTrie(Any[],
                                bt.shift - shiftby,
                                0,
                                int(bt.maxlength / trielen))
            return BitmappedTrie(BitmappedTrie[append(bt2, el)],
                                 bt.shift,
                                 1 + length(bt),
                                 bt.maxlength)
        elseif length(bt) < bt.maxlength
            if length(bt.self[end]) == bt.self[end].maxlength
                newself = copy_to_len(bt.self, 1 + length(bt.self))
                newself[end] = append(BitmappedTrie(Any[],
                                                    bt.shift - shiftby,
                                                    0,
                                                    int(bt.maxlength / trielen)),
                                      el)
                return BitmappedTrie(newself, bt.shift, 1 + length(bt), bt.maxlength)
            else
                newself = bt.self[1:end]
                newself[end] = append(bt.self[end], el)
                return BitmappedTrie(newself, bt.shift, 1 + length(bt), bt.maxlength)
            end
        end
    end
    # Construct a promoted BitmappedTrie
    bt2 = BitmappedTrie(Any[], bt.shift, 0, bt.maxlength)
    BitmappedTrie(BitmappedTrie[bt, append(bt2, el)],
                  bt.shift + shiftby,
                  1 + length(bt),
                  bt.maxlength * trielen)
end
push = append

function Base.getindex(bt::BitmappedTrie, i::Int)
    # Decrement i so that the bitwise math works out. It will be incremented
    # before indexing into Arrays.
    i -= 1
    if bt.shift == 0
        bt.self[(i & andval) + 1]
    else
        bt.self[((i >>> bt.shift) & andval) + 1][i + 1]
    end
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
        BitmappedTrie(bt.self[1:end-1], 0, bt.length - 1, bt.maxlength)
    else
        newself = bt.self[1:end]
        newself[end] = pop(newself[end])
        BitmappedTrie(newself, bt.shift, bt.length - 1, bt.maxlength)
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
