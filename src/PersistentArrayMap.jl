immutable PersistentArrayMap{K, V} <: PersistentMap{K, V}
    kvs::Vector{KVPair{K, V}}

    PersistentArrayMap(kvs::Vector{KVPair{K, V}}) = new(kvs)
    PersistentArrayMap() = new(KVPair{K, V}[])
end
PersistentArrayMap{K, V}(kvs::(K, V)...) =
    PersistentArrayMap{K, V}(KVPair{K, V}[KVPair(k, v) for (k, v) in kvs])
PersistentArrayMap(; kwargs...) = PersistentArrayMap(kwargs...)

Base.isequal(m1::PersistentArrayMap, m2::PersistentArrayMap) =
    isequal(Set(m1.kvs...), Set(m2.kvs...))
==(m1::PersistentArrayMap, m2::PersistentArrayMap) =
    isequal(m1, m2)

Base.length(m::PersistentArrayMap)  = length(m.kvs)
Base.isempty(m::PersistentArrayMap) = length(m) == 0

findkeyidx(m::PersistentArrayMap, k) = findfirst((kv) -> kv.key == k, m.kvs)

function _get(m::PersistentArrayMap, k, default, hasdefault::Bool)
    for kv in m.kvs
        kv.key == k && return kv.value
    end
    hasdefault ? default : default()
end

Base.get(m::PersistentArrayMap, k) =
    _get(m, k, ()->error("key not found: $k"), false)
Base.get(m::PersistentArrayMap, k, default) =
    _get(m, k, default, true)
Base.getindex(m::PersistentArrayMap, k) = get(m, k)

Base.haskey(m::PersistentArrayMap, k) = get(m, k, NotFound()) != NotFound()

function assoc{K, V}(m::PersistentArrayMap{K, V}, k, v)
    idx = findkeyidx(m, k)
    idx == 0 && return PersistentArrayMap{K, V}(push!(m.kvs[1:end], KVPair(k, v)))

    kvs = m.kvs[1:end]
    kvs[idx] = KVPair(k, v)
    PersistentArrayMap{K, V}(kvs)
end

function dissoc{K, V}(m::PersistentArrayMap{K, V}, k)
    idx = findkeyidx(m, k)
    idx == 0 && return m

    kvs = m.kvs[1:end]
    splice!(kvs, idx)
    PersistentArrayMap{K, V}(kvs)
end

Base.start(m::PersistentArrayMap)   = 1
Base.done(m::PersistentArrayMap, i) = i > length(m)
Base.next(m::PersistentArrayMap, i) = (convert(Tuple, m.kvs[i]), i+1)

Base.map(f::Union(DataType, Function), m::PersistentArrayMap) =
    PersistentArrayMap([f(kv) for kv in m]...)

Base.show{K, V}(io::IO, m::PersistentArrayMap{K, V}) =
    print(io, "Persistent{$K, $V}$(m.kvs)")
