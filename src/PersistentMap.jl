abstract type PersistentMap{K, V} <: AbstractDict{K, V} end

struct NotFound end

struct PersistentArrayMap{K, V} <: PersistentMap{K, V}
    kvs::Vector{Pair{K, V}}
end
PersistentArrayMap{K, V}() where {K, V} =
    PersistentArrayMap{K, V}(Pair{K, V}[])
PersistentArrayMap(kvs::(Union{Tuple{K, V}, Pair{K, V}})...) where {K, V} =
    PersistentArrayMap{K, V}(Pair{K, V}[Pair(k, v) for (k, v) in kvs])
PersistentArrayMap(; kwargs...) = PersistentArrayMap(kwargs...)

Base.isequal(m1::PersistentArrayMap, m2::PersistentArrayMap) =
    isequal(Set(m1.kvs), Set(m2.kvs))
==(m1::PersistentArrayMap, m2::PersistentArrayMap) =
    Set(m1.kvs) == Set(m2.kvs)

Base.length(m::PersistentArrayMap)  = length(m.kvs)
Base.isempty(m::PersistentArrayMap) = length(m) == 0

findkeyidx(m::PersistentArrayMap, k) = findfirst(kv -> kv[1] == k, m.kvs)

function _get(m::PersistentArrayMap, k, default, hasdefault::Bool)
    for kv in m.kvs
        kv[1] == k && return kv[2]
    end
    hasdefault ? default : default()
end

Base.get(m::PersistentArrayMap, k) =
    _get(m, k, ()->error("key not found: $k"), false)
Base.get(m::PersistentArrayMap, k, default) =
    _get(m, k, default, true)
Base.getindex(m::PersistentArrayMap, k) = get(m, k)

Base.haskey(m::PersistentArrayMap, k) = get(m, k, NotFound()) != NotFound()

function assoc(m::PersistentArrayMap{K, V}, k, v) where {K, V}
    idx = findkeyidx(m, k)
    idx === nothing && return PersistentArrayMap{K, V}(push!(m.kvs[1:end], Pair{K,V}(k, v)))

    kvs = m.kvs[1:end]
    kvs[idx] = Pair{K,V}(k, v)
    PersistentArrayMap{K, V}(kvs)
end

function dissoc(m::PersistentArrayMap{K, V}, k) where {K, V}
    idx = findkeyidx(m, k)
    idx === nothing && return m

    kvs = m.kvs[1:end]
    splice!(kvs, idx)
    PersistentArrayMap{K, V}(kvs)
end

function Base.iterate(m::PersistentArrayMap, i = 1)
    if i > length(m)
        return nothing
    else
        return (m.kvs[i], i + 1)
    end
end

Base.map(f::( Union{DataType, Function}), m::PersistentArrayMap) =
    PersistentArrayMap([f(kv) for kv in m]...)

Base.show(io::IO, ::MIME"text/plain", m::PersistentArrayMap{K, V}) where {K, V} =
    print(io, "Persistent{$K, $V}$(m.kvs)")


# Persistent Hash Maps
# ====================

struct PersistentHashMap{K, V} <: PersistentMap{K, V}
    trie::SparseBitmappedTrie{PersistentArrayMap{K, V}}
    length::Int
end
PersistentHashMap{K, V}() where {K, V} =
    PersistentHashMap{K, V}(SparseNode(PersistentArrayMap{K, V}), 0)

function PersistentHashMap(itr)
    if length(itr) == 0
        return PersistentHashMap()
    end
    K, V = typejoin(map(typeof, itr)...).types
    m = PersistentHashMap{K, V}()
    for (k, v) in itr
        m = assoc(m, k, v)
    end
    m
end

function PersistentHashMap(kvs::(Tuple{Any, Any})...)
    PersistentHashMap([kvs...])
end

function PersistentHashMap(kvs::(Pair)...)
    PersistentHashMap([kvs...])
end

function PersistentHashMap(; kwargs...)
    isempty(kwargs) ?
    PersistentHashMap{Any, Any}() :
    PersistentHashMap(kwargs...)
end

Base.length(m::PersistentHashMap) = m.length
Base.isempty(m::PersistentHashMap) = length(m) == 0

zipd(x,y) = map(p -> p[1] => p[2], zip(x,y))
Base.isequal(m1::PersistentHashMap, m2::PersistentHashMap) =
    length(m1) == length(m2) && all(x -> isequal(x...), zipd(m1, m2))

tup_eq(x) = x[1] == x[2]
==(m1::PersistentHashMap, m2::PersistentHashMap) =
    length(m1) == length(m2) && all(x -> x[1] == x[2], zipd(m1, m2))

function _update(f::Function, m::PersistentHashMap{K, V}, key) where {K, V}
    keyhash = reinterpret(Int, hash(key))
    arraymap = get(m.trie, keyhash, PersistentArrayMap{K, V}())
    newmap = f(arraymap)
    newtrie, _ = update(m.trie, keyhash, newmap)
    PersistentHashMap{K, V}(newtrie,
                            m.length + (length(newmap) < length(arraymap) ? -1 :
                                        length(newmap) > length(arraymap) ? 1 :
                                        0))
end

function assoc(m::PersistentHashMap{K, V}, key, value) where {K, V}
    _update(m, key) do arraymap
        assoc(arraymap, key, value)
    end
end

function dissoc(m::PersistentHashMap, key)
    _update(m, key) do arraymap
        dissoc(arraymap, key)
    end
end

function Base.getindex(m::PersistentHashMap, key)
    val = get(m.trie, reinterpret(Int, hash(key)), NotFound())
    (val === NotFound()) && error("key not found")
    val[key]
end

Base.get(m::PersistentHashMap, key) = m[key]
function Base.get(m::PersistentHashMap, key, default)
    val = get(m.trie, reinterpret(Int, hash(key)), NotFound())
    (val === NotFound()) && return default
    val[key]
end

function Base.haskey(m::PersistentHashMap, key)
    get(m.trie, reinterpret(Int, hash(key)), NotFound()) != NotFound()
end

function Base.iterate(m::PersistentHashMap)
    trie_iter_result = iterate(m.trie)
    if trie_iter_result === nothing
        return nothing
    else
        arrmap, triestate = trie_iter_result
        kvs = arrmap.kvs
        return iterate(m, (kvs, triestate))
    end
end

function Base.iterate(m::PersistentHashMap, (kvs, triestate))
    if isempty(kvs) && isempty(triestate)
        return nothing
    else
        if isempty(kvs)
            arrmap, triestate = iterate(m.trie, triestate)
            return iterate(m, (arrmap.kvs, triestate))
        else
            return (kvs[1], (kvs[2:end], triestate))
        end
    end
end

function Base.map(f::( Union{Function, DataType}), m::PersistentHashMap)
    PersistentHashMap([f(kv) for kv in m]...)
end

function Base.filter(f::Function, m::PersistentHashMap{K, V}) where {K, V}
    arr = Array{Pair{K, V},1}()
    for el in m
        f(el) && push!(arr, el)
    end
    isempty(arr) ? PersistentHashMap{K, V}() : PersistentHashMap(arr...)
end

# Suppress ambiguity warning while allowing merging with array
function _merge(d::PersistentHashMap, others...)
    acc = d
    for other in others
        for (k, v) in other
            acc = assoc(acc, k, v)
        end
    end
    acc
end

# This definition suppresses ambiguity warning
Base.merge(d::PersistentHashMap, others::AbstractDict...) =
    _merge(d, others...)
Base.merge(d::PersistentHashMap, others...) =
    _merge(d, others...)

 function Base.show(io::IO, ::MIME"text/plain", m::PersistentHashMap{K, V}) where {K, V}
    print(io, "Persistent{$K, $V}[")
    print(io, join(["$k => $v" for (k, v) in m], ", "))
    print(io, "]")
end
