# `shiftby` is equal to the number of bits required to represent index information
# for one level of the BitmappedTrie.
#
# Here, `shiftby` is 5, which means that the BitmappedTrie Arrays will be length 32.
const shiftby = 5
const trielen = 2^shiftby

abstract BitmappedTrie{T}

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

mask(t::BitmappedTrie, i::Int) = (((i - 1) >>> shift(t)) & (trielen - 1)) + 1

Base.endof(t::BitmappedTrie) = length(t)

Base.length(t::BitmappedTrie) =
    error("$(typeof(t)) does not implement Base.length")
shift(t::BitmappedTrie) =
    error("$(typeof(t)) does not implement FunctionalCollections.shift")
maxlength(t::BitmappedTrie) =
    error("$(typeof(t)) does not implement FunctionalCollections.maxlength")

function Base.isequal(t1::BitmappedTrie, t2::BitmappedTrie)
    length(t1)    == length(t2)    &&
    shift(t1)     == shift(t2)     &&
    maxlength(t1) == maxlength(t2) &&
    t1.self       == t2.self
end
