immutable PersistentSet{T}
    dict::PersistentHashMap{T, Void}
    # TODO: this constructor is inconsistent with everything else
    # and with Set in base; probably good to deprecate.
    (::Type{PersistentSet{T}}){T}(d::PersistentHashMap{T, Void}) = new{T}(d)
    (::Type{PersistentSet{T}}){T}() = new{T}(PersistentHashMap{T, Void}())
end
(::Type{PersistentSet{T}}){T}(itr) = _union(PersistentSet{T}(), itr)
PersistentSet() = PersistentSet{Any}()
PersistentSet(itr) = PersistentSet{eltype(itr)}(itr)

Base.@deprecate(PersistentSet{T}(x1::T, x2::T, xs::T...),
                PersistentSet{T}(T[x1, x2, xs...]))

Base.hash(s::PersistentSet,h::UInt) =
    hash(s.dict, h+(UInt(0xf7dca1a5fd7090be)))

Base.conj{T}(s::PersistentSet{T}, val) =
    PersistentSet{T}(assoc(s.dict, val, nothing))

push(s::PersistentSet, val) = conj(s, val)

disj{T}(s::PersistentSet{T}, val) =
    PersistentSet{T}(dissoc(s.dict, val))

Base.length(s::PersistentSet) = length(s.dict)
Base.eltype{T}(s::PersistentSet{T}) = T

Base.isequal(s1::PersistentSet, s2::PersistentSet) = isequal(s1.dict, s2.dict)
==(s1::PersistentSet, s2::PersistentSet) = s1.dict == s2.dict

Base.in(val, s::PersistentSet) = haskey(s.dict, val)

Base.start(s::PersistentSet) = start(s.dict)
Base.done(s::PersistentSet, state) = done(s.dict, state)
function Base.next(s::PersistentSet, state)
    kv, state = next(s.dict, state)
    (kv[1], state)
end

function Base.filter{T}(f::Function, s::PersistentSet{T})
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
    reduce(_union, PersistentSet{join_eltype(x, xs...)}(), [x, xs...])

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
