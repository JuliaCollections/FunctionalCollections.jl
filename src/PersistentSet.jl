immutable PersistentSet{T}
    dict::PersistentHashMap{T, Nothing}

    PersistentSet(d::PersistentHashMap{T, Nothing}) = new(d)
    PersistentSet() = new(PersistentHashMap{T, Nothing}())
end

PersistentSet{T}(vals::T...) =
    PersistentSet{T}(PersistentHashMap([(val, nothing) for val in vals]...))

Base.conj{T}(s::PersistentSet{T}, val) =
    PersistentSet{T}(assoc(s.dict, val, nothing))

disj{T}(s::PersistentSet{T}, val) =
    PersistentSet{T}(dissoc(s.dict, val))

Base.length(s::PersistentSet) = length(s.dict)

Base.isequal(s1::PersistentSet, s2::PersistentSet) = s1.dict == s2.dict

Base.contains(s::PersistentSet, val) = haskey(s.dict, val)

Base.start(s::PersistentSet) = start(s.dict)
Base.done(s::PersistentSet, state) = done(s.dict, state)
function Base.next(s::PersistentSet, state)
    kv, state = next(s.dict, state)
    (kv[1], state)
end

Base.filter{T}(f::Function, s::PersistentSet{T}) =
    PersistentSet{T}(filter((kv) -> f(kv[1]), s.dict))

function Base.setdiff(l::PersistentSet, r::Union(PersistentSet, Set))
    notinr(el) = !contains(r, el)
    filter(notinr, l)
end

import Base.-
-(l::PersistentSet, r::Union(PersistentSet, Set)) = setdiff(l, r)

Base.isempty(s::PersistentSet) = length(s.dict) == 0

function Base.union(s1::PersistentSet, s2::PersistentSet)
    for el in s2
        s1 = conj(s1, el)
    end
    s1
end
Base.union(s::PersistentSet...) = reduce(union, s)

function Base.isless(s1::PersistentSet, s2::PersistentSet)
    length(s1) < length(s2) &&
    all(el -> contains(s2, el), s1)
end

import Base.<=
<=(s1::PersistentSet, s2::PersistentSet) = all(el -> contains(s2, el), s1)

function Base.show{T}(io::IO, s::PersistentSet{T})
    print(io, "PersistentSet{$T}(")
    print(io, join([k for (k, v) in s.dict], ", "))
    print(io, ")")
end
