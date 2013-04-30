immutable PersistentHashMap{K, V} <: PersistentMap{K, V}
    trie::SparseBitmappedTrie{PersistentArrayMap{K, V}}
    length::Int

    PersistentHashMap(trie, length) = new(trie, length)
    PersistentHashMap() = new(SparseNode(PersistentArrayMap{K, V}), 0)
end

function PersistentHashMap{K, V}(kvs::(K, V)...)
    m = PersistentHashMap{K, V}()
    for (key, value) in kvs
        m = assoc(m, key, value)
    end
    m
end
PersistentHashMap(; kwargs...) = PersistentHashMap(kwargs...)

Base.length(m::PersistentHashMap) = m.length
Base.isempty(m::PersistentHashMap) = length(m) == 0

function Base.isequal(m1::PersistentHashMap, m2::PersistentHashMap)
    length(m1) == length(m2) && all(x -> x[1] == x[2], zip(m1.trie, m2.trie))
end

function _update{K, V}(f::Function, m::PersistentHashMap{K, V}, key::K)
    keyhash = int(hash(key))
    arraymap = get(m.trie, keyhash, PersistentArrayMap{K, V}())
    newmap = f(arraymap)
    newtrie, _ = update(m.trie, keyhash, newmap)
    PersistentHashMap{K, V}(newtrie,
                            m.length + (length(newmap) < length(arraymap) ? -1 :
                                        length(newmap) > length(arraymap) ? 1 :
                                        0))
end

function assoc{K, V}(m::PersistentHashMap{K, V}, key::K, value::V)
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
    val = get(m.trie, int(hash(key)), NotFound())
    is(val, NotFound()) && error("key not found")
    val[key]
end

Base.get(m::PersistentHashMap, key) = m[key]
function Base.get(m::PersistentHashMap, key, default)
    val = get(m.trie, int(hash(key)), NotFound())
    is(val, NotFound()) && return default
    val[key]
end

function Base.haskey(m::PersistentHashMap, key)
    get(m.trie, int(hash(key)), NotFound()) != NotFound()
end

function Base.start(m::PersistentHashMap)
    state = start(m.trie)
    done(m.trie, state) && return ({}, state)
    arrmap, triestate = next(m.trie, state)
    (arrmap.kvs, triestate)
end
Base.done(m::PersistentHashMap, state) = isempty(state[1]) && done(m.trie, state[2])

function Base.next(m::PersistentHashMap, state)
    kvs, triestate = state
    if isempty(kvs)
        arrmap, triestate = next(m.trie, triestate)
        next(m, (arrmap.kvs, triestate))
    else
        (convert(Tuple, kvs[1]), (kvs[2:end], triestate))
    end
end

Base.map(f, m::PersistentHashMap) =
    PersistentHashMap([f(kv) for kv in m]...)

function Base.show{K, V}(io::IO, m::PersistentHashMap{K, V})
    print(io, "Persistent{$K, $V}[")
    print(io, join(["$k => $v" for (k, v) in m], ", "))
    print(io, "]")
end
