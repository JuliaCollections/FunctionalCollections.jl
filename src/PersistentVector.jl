# In this initial implementation, a PersistentVector is a BitmappedTrie. This
# may change, with the Vector becoming more of a wrapper.
#
typealias PersistentVector BitmappedTrie
typealias TransientVector TransientBitmappedTrie

function PersistentVector(self::Array)
    if length(self) <= trielen
        PersistentVector(self, 0, length(self), trielen)
    else
        tv = TransientVector()
        for el in self
            push!(tv, el)
        end
        persist!(tv)
    end
end

# Slow iteration
Base.start(pv::PersistentVector) = 1
Base.done(pv::PersistentVector, i::Int) = i > pv.length
Base.next(pv::PersistentVector, i::Int) = (pv[i], i+1)

function Base.map(f::Function, pv::PersistentVector)
    tv = TransientVector()
    for el in pv
        push!(tv, f(el))
    end
    persist!(tv)
end

function Base.hash(pv::PersistentVector)
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

function print_trie(io::IO, t::Trie, head::String)
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

Base.show(io::IO, pv::PersistentVector) = print_trie(io, pv, "Persistent")
Base.show(io::IO, tv::TransientVector) = print_trie(io, tv, "Transient")
