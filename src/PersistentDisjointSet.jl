struct PersistentDisjointSet{T}
    table::PersistentHashMap{T,T}
    heights::PersistentHashMap{T,UInt8}
end
PersistentDisjointSet{T}() where {T} = PersistentDisjointSet{T}(PersistentHashMap{T,T}(),PersistentHashMap{T,UInt8}())


height(t::PersistentDisjointSet{T},i::T) where {T} =  get(t.heights,i,zero(UInt8))

function Base.getindex(t::PersistentDisjointSet{T},i::T) where {T} 
    while haskey(t.table,i) # In a persistent setting, writes cost memory, so path compression may not be worth the allocations.
        i = t.table[i]      # Height balancing already guarentees finding the root in floor(lg(N)) lookups.
    end
    i
end

function Base.union(t::PersistentDisjointSet{T},i::T,j::T) where {T}
    i = t[i];j=t[j]
    if i == j return t end
    if height(t,i) > height(t,j)
        PersistentDisjointSet(assoc(t.table,j,i),t.heights)
    elseif height(t,i) < height(t,j)
        PersistentDisjointSet(assoc(t.table,i,j),t.heights)
    else
        PersistentDisjointSet(assoc(t.table,j,i),assoc(t.heights,i,height(t,i) + 1))
    end     
end

function Base.show(io::IO,t::PersistentDisjointSet{T}) where {T}
    Base.print(io,"PersistentDisjointSet{$T}")
    Base.print(io,sort!(map(x->first(x) => t[last(x)],collect(pairs(t.table)));by=x->(last(x),first(x))))
end