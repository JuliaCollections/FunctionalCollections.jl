__precompile__()
module FunctionalCollections

import Base.==

include("BitmappedVectorTrie.jl")

include("PersistentVector.jl")

const pvec = PersistentVector

export PersistentVector, pvec,
       append, push,
       assoc,
       peek,
       pop

include("PersistentMap.jl")

const phmap = PersistentHashMap

export PersistentArrayMap,
       PersistentHashMap, phmap,
       assoc,
       dissoc

include("PersistentSet.jl")

const pset = PersistentSet

export PersistentSet, pset,
       disj

include("PersistentList.jl")

const plist = PersistentList

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
    kvtuples = [:($(esc(kv.args[end-1])), $(esc(kv.args[end])))
                for kv in ex.args[2:end]]
    :(phmap($(kvtuples...)))
end

using Base.Meta: isexpr
macro Persistent(ex)
    if isexpr(ex, [:vcat, :vect])
        fromexpr(ex, pvec)
    elseif isexpr(ex, :call) && ex.args[1] === :Set
        fromexpr(ex, pset)
    elseif isexpr(ex, :call) && ex.args[1] === :Dict
        fromexpr(ex, phmap)
    else
        error("Unsupported @Persistent syntax")
    end
end

end # module FunctionalCollections
