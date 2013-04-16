module PersistentDataStructures

export PersistentVector,
       TransientVector,
       persist!,
       append, push,
       # Base.getindex,
       update,
       peek,
       pop

include("BitmappedVectorTrie.jl")
include("PersistentVector.jl")

end # module PersistentDataStructures
