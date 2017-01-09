module FunctionalCollections

import Base.==

include("BitmappedVectorTrie.jl")

include("PersistentVector.jl")

typealias pvec PersistentVector

export PersistentVector, pvec,
       append, push,
       assoc,
       peek,
       pop

include("PersistentMap.jl")

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

export @Persistent

fromexpr(ex::Expr, ::Type{pvec}) = :(pvec($(esc(ex))))
fromexpr(ex::Expr, ::Type{pset}) = :(pset($(map(esc, ex.args[2:end])...)))
function fromexpr(ex::Expr, ::Type{phmap})
    kvtuples = [Expr(:tuple, map(esc, kv.args)...)
                for kv in (ex.head == :dict ? ex.args : ex.args[2:end])]
    :(phmap($(kvtuples...)))
end

macro Persistent(ex)
    hd = ex.head

    if (hd === :vcat) || (hd === :cell1d) || (hd === :vect)
        fromexpr(ex, pvec)
    elseif (hd === :call) && (ex.args[1] === :Set)
        fromexpr(ex, pset)
    elseif (hd === :dict) || ((hd === :call) && (ex.args[1] === :Dict))
        fromexpr(ex, phmap)
    else
        error("Unsupported @Persistent syntax")
    end
end

end # module FunctionalCollections
