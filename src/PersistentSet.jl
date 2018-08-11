struct PersistentSet{T}
    dict::PersistentHashMap{T, Nothing}
    # TODO: this constructor is inconsistent with everything else
    # and with Set in base; probably good to deprecate.
    PersistentSet{T}(d::PersistentHashMap{T, Nothing}) where {T} = new{T}(d)
    PersistentSet{T}() where {T} = new{T}(PersistentHashMap{T, Nothing}())
end
PersistentSet{T}(itr) where {T} = _union(PersistentSet{T}(), itr)
PersistentSet() = PersistentSet{Any}()
PersistentSet(itr) = PersistentSet{eltype(itr)}(itr)

Base.@deprecate(PersistentSet(x1::T, x2::T, xs::T...) where {T},
                PersistentSet(T[x1, x2, xs...]))

Base.hash(s::PersistentSet,h::UInt) =
    hash(s.dict, h+(UInt(0xf7dca1a5fd7090be)))

Base.conj(s::PersistentSet{T}, val) where {T} =
    PersistentSet{T}(assoc(s.dict, val, nothing))

push(s::PersistentSet, val) = conj(s, val)

disj(s::PersistentSet{T}, val) where {T} =
    PersistentSet{T}(dissoc(s.dict, val))

Base.length(s::PersistentSet) = length(s.dict)
Base.eltype(s::PersistentSet{T}) where {T} = T

Base.isequal(s1::PersistentSet, s2::PersistentSet) = isequal(s1.dict, s2.dict)
==(s1::PersistentSet, s2::PersistentSet) = s1.dict == s2.dict

Base.in(val, s::PersistentSet) = haskey(s.dict, val)

Base.iterate(s::PersistentSet) = iterate(s, iterate(s.dict))
Base.iterate(s::PersistentSet, ::Nothing) = nothing
Base.iterate(s::PersistentSet, (kv, dict_state)) = (kv[1], iterate(s.dict, dict_state))

function Base.filter(f::Function, s::PersistentSet{T}) where T
    filtered = filter((kv) -> f(kv[1]), s.dict)
    PersistentSet{T}(keys(filtered))
end

function Base.setdiff(l::PersistentSet, r::( Union{PersistentSet, Set}))
    notinr(el) = !(el in r)
    filter(notinr, l)
end

import Base.-
-(l::PersistentSet, r::( Union{PersistentSet, Set})) = setdiff(l, r)

Base.isempty(s::PersistentSet) = length(s.dict) == 0

function _union(s::PersistentSet, xs)
    for x in xs
        s = conj(s, x)
    end
    s
end

join_eltype() =  Union{}
join_eltype(v1, vs...) = typejoin(eltype(v1), join_eltype(vs...))

Base.union(s::PersistentSet) = s
Base.union(x::PersistentSet, xs::PersistentSet...) =
    reduce(_union, [x, xs...], init=PersistentSet{join_eltype(x, xs...)}())

function Base.isless(s1::PersistentSet, s2::PersistentSet)
    length(s1) < length(s2) &&
    all(el -> el in s2, s1)
end

import Base.<=
<=(s1::PersistentSet, s2::PersistentSet) = all(el -> el in s2, s1)

function Base.show(io::IO, s::PersistentSet{T}) where T
    print(io, "PersistentSet{$T}(")
    print(io, join([k for (k, v) in s.dict], ", "))
    print(io, ")")
end
