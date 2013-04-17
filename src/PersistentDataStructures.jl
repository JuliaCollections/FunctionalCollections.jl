module PersistentDataStructures

export PersistentVector,
       append, push,
       # Base.getindex,
       update,
       peek,
       pop

include("BitmappedVectorTrie.jl")
include("PersistentVector.jl")

end # module PersistentDataStructures
