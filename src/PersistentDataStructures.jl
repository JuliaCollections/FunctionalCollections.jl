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

end # module PersistentDataStructures
