abstract PersistentMap{K, V} <: Associative{K, V}

type NotFound end

immutable PersistentArrayMap{K, V} <: PersistentMap{K, V}
    kvs::Vector{Pair{K, V}}

    PersistentArrayMap(kvs::Vector{Pair{K, V}}) = new(kvs)
    PersistentArrayMap() = new(Pair{K, V}[])
end
PersistentArrayMap{K, V}(kvs::(Tuple{K, V})...) =
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

function assoc{K, V}(m::PersistentArrayMap{K, V}, k, v)
    idx = findkeyidx(m, k)
    idx == 0 && return PersistentArrayMap{K, V}(push!(m.kvs[1:end], Pair(k, v)))

    kvs = m.kvs[1:end]
    kvs[idx] = Pair(k, v)
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
Base.next(m::PersistentArrayMap, i) = (m.kvs[i], i+1)

Base.map(f::( Union{DataType, Function}), m::PersistentArrayMap) =
    PersistentArrayMap([f(kv) for kv in m]...)

Base.show{K, V}(io::IO, ::MIME"text/plain", m::PersistentArrayMap{K, V}) =
    print(io, "Persistent{$K, $V}$(m.kvs)")


# Persistent Hash Maps
# ====================

immutable PersistentHashMap{K, V} <: PersistentMap{K, V}
    trie::SparseBitmappedTrie{PersistentArrayMap{K, V}}
    length::Int

    PersistentHashMap(trie, length) = new(trie, length)
    PersistentHashMap() = new(SparseNode(PersistentArrayMap{K, V}), 0)
end

function PersistentHashMap(itr)
    if length(itr) == 0
        return PersistentHashMap()
    end
    if VERSION >= v"0.4.0-dev"
        K, V = typejoin(map(typeof, itr)...).types
    else
        K, V = typejoin(map(typeof, itr)...)
    end
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

function _update{K, V}(f::Function, m::PersistentHashMap{K, V}, key)
    keyhash = reinterpret(Int, hash(key))
    arraymap = get(m.trie, keyhash, PersistentArrayMap{K, V}())
    newmap = f(arraymap)
    newtrie, _ = update(m.trie, keyhash, newmap)
    PersistentHashMap{K, V}(newtrie,
                            m.length + (length(newmap) < length(arraymap) ? -1 :
                                        length(newmap) > length(arraymap) ? 1 :
                                        0))
end

function assoc{K, V}(m::PersistentHashMap{K, V}, key, value)
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

function Base.start(m::PersistentHashMap)
    state = start(m.trie)
    done(m.trie, state) && return (Any[], state)
    arrmap, triestate = next(m.trie, state)
    (arrmap.kvs, triestate)
end
Base.done(m::PersistentHashMap, state) =
    isempty(state[1]) && done(m.trie, state[2])

function Base.next(m::PersistentHashMap, state)
    kvs, triestate = state
    if isempty(kvs)
        arrmap, triestate = next(m.trie, triestate)
        next(m, (arrmap.kvs, triestate))
    else
        (kvs[1], (kvs[2:end], triestate))
    end
end

function Base.map(f::( Union{Function, DataType}), m::PersistentHashMap)
    PersistentHashMap([f(kv) for kv in m]...)
end

function Base.filter{K, V}(f::Function, m::PersistentHashMap{K, V})
    arr = Array((Pair{K, V}), 0)
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
Base.merge(d::PersistentHashMap, others::Associative...) =
    _merge(d, others...)
Base.merge(d::PersistentHashMap, others...) =
    _merge(d, others...)

 function Base.show{K, V}(io::IO, ::MIME"text/plain", m::PersistentHashMap{K, V})
    print(io, "Persistent{$K, $V}[")
    print(io, join(["$k => $v" for (k, v) in m], ", "))
    print(io, "]")
end
