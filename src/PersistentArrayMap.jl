immutable PersistentArrayMap{K, V} <: PersistentMap{K, V}
    kvs::Array{KVPair{K, V}}

    PersistentArrayMap(kvs::Array{KVPair{K, V}}) = new(kvs)
    PersistentArrayMap() = new(KVPair{K, V}[])
end
PersistentArrayMap{K, V}(kvs::(K, V)...) =
    PersistentArrayMap{K, V}(KVPair{K, V}[KVPair(k, v) for (k, v) in kvs])
PersistentArrayMap(; kwargs...) = PersistentArrayMap(kwargs...)

Base.isequal(m1::PersistentArrayMap, m2::PersistentArrayMap) =
    isequal(Set(m1.kvs...), Set(m2.kvs...))

Base.length(m::PersistentArrayMap)  = length(m.kvs)
Base.isempty(m::PersistentArrayMap) = length(m) == 0

findkeyidx(m::PersistentArrayMap, k) = findfirst((kv) -> kv.key == k, m.kvs)

function _get{K, V}(m::PersistentArrayMap{K, V}, k::K, default, hasdefault::Bool)
    for kv in m.kvs
        kv.key == k && return kv.value
    end
    hasdefault ? default : default()
end

Base.get{K, V}(m::PersistentArrayMap{K, V}, k::K) =
    _get(m, k, ()->error("key not found: $k"), false)
Base.get{K, V}(m::PersistentArrayMap{K, V}, k::K, default) =
    _get(m, k, default, true)
Base.getindex{K, V}(m::PersistentArrayMap{K, V}, k::K) = get(m, k)

Base.has(m::PersistentArrayMap, k) = get(m, k, NotFound()) != NotFound()

function assoc{K, V}(m::PersistentArrayMap{K, V}, k::K, v::V)
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
    delete!(kvs, idx)
    PersistentArrayMap{K, V}(kvs)
end

Base.start(m::PersistentArrayMap)   = 1
Base.done(m::PersistentArrayMap, i) = i > length(m)
Base.next(m::PersistentArrayMap, i) = (convert(Tuple, m.kvs[i]), i+1)

Base.map{K, V}(f, m::PersistentArrayMap{K, V}) =
    PersistentArrayMap([f(kv) for kv in m]...)

Base.show{K, V}(io::IO, m::PersistentArrayMap{K, V}) =
    print(io, "Persistent{$K, $V}$(m.kvs)")
