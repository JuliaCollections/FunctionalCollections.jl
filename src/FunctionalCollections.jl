module FunctionalCollections

include("BitmappedVectorTrie.jl")

include("PersistentVector.jl")

typealias pvec PersistentVector

export PersistentVector, pvec,
       append, push,
       update,
       peek,
       pop

include("PersistentMap.jl")
include("PersistentArrayMap.jl")
include("PersistentHashMap.jl")

typealias phmap PersistentHashMap

export PersistentArrayMap,
       PersistentHashMap, phmap,
       assoc,
       dissoc

include("PersistentSet.jl")

typealias pset PersistentSet

export PersistentSet, pset,
       disj

include("List.jl")

export List, EmptyList,
       cons,
       head,
       tail

end # module FunctionalCollections
