immutable PersistentSet{T}
    dict::PersistentHashMap{T, Nothing}

    PersistentSet(d::PersistentHashMap{T, Nothing}) = new(d)
    PersistentSet() = new(PersistentHashMap{T, Nothing}())
    PersistentSet(itr) = union(new(PersistentHashMap{T,Nothing}()), itr)
end
PersistentSet() = PersistentSet{Any}()
PersistentSet(itr) = PersistentSet{eltype(itr)}(itr)

PersistentSet{T}(vals::T...) =
    PersistentSet{T}(PersistentHashMap([(val, nothing) for val in vals]...))

Base.conj{T}(s::PersistentSet{T}, val) =
    PersistentSet{T}(assoc(s.dict, val, nothing))

push(s::PersistentSet, val) = conj(s, val)

disj{T}(s::PersistentSet{T}, val) =
    PersistentSet{T}(dissoc(s.dict, val))

Base.length(s::PersistentSet) = length(s.dict)
Base.eltype{T}(s::PersistentSet{T}) = T

Base.isequal(s1::PersistentSet, s2::PersistentSet) = s1.dict == s2.dict

Base.in(val, s::PersistentSet) = haskey(s.dict, val)

Base.start(s::PersistentSet) = start(s.dict)
Base.done(s::PersistentSet, state) = done(s.dict, state)
function Base.next(s::PersistentSet, state)
    kv, state = next(s.dict, state)
    (kv[1], state)
end

Base.filter{T}(f::Function, s::PersistentSet{T}) =
    PersistentSet{T}(filter((kv) -> f(kv[1]), s.dict))

function Base.setdiff(l::PersistentSet, r::Union(PersistentSet, Set))
    notinr(el) = !(el in r)
    filter(notinr, l)
end

import Base.-
-(l::PersistentSet, r::Union(PersistentSet, Set)) = setdiff(l, r)

Base.isempty(s::PersistentSet) = length(s.dict) == 0

function Base.union(s::PersistentSet, xs)
    for x in xs
        s = conj(s, x)
    end
    s
end
Base.union(s::PersistentSet...) = reduce(union, s)

function Base.isless(s1::PersistentSet, s2::PersistentSet)
    length(s1) < length(s2) &&
    all(el -> el in s2, s1)
end

import Base.<=
<=(s1::PersistentSet, s2::PersistentSet) = all(el -> el in s2, s1)

function Base.show{T}(io::IO, s::PersistentSet{T})
    print(io, "PersistentSet{$T}(")
    print(io, join([k for (k, v) in s.dict], ", "))
    print(io, ")")
end
