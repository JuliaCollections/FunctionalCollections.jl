module FunctionalCollections

include("BitmappedVectorTrie.jl")

include("PersistentVector.jl")

typealias pvec PersistentVector

export PersistentVector, pvec,
       append, push,
       assoc,
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

include("PersistentList.jl")

typealias plist PersistentList

export PersistentList, plist,
       EmptyList,
       cons, ..,
       head,
       tail

include("PersistentQueue.jl")

export PersistentQueue, queue,
       enq

end # module FunctionalCollections
