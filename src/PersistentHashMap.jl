immutable PersistentHashMap{K, V}
    trie::SparseBitmappedTrie{PersistentArrayMap{K, V}}
    
    PersistentHashMap(trie) = new(trie)
    PersistentHashMap() = new(SparseNode(PersistentArrayMap{K, V}))
end

function PersistentHashMap{K, V}(kvs::(K, V)...)
    m = PersistentHashMap{K, V}()
    for (key, value) in kvs
        m = assoc(m, key, value)
    end
    m
end
PersistentHashMap(; kwargs...) = PersistentHashMap(kwargs...)


Base.length(m::PersistentHashMap) = length(m.trie)
Base.isempty(m::PersistentHashMap) = length(m) == 0

function Base.isequal(m1::PersistentHashMap, m2::PersistentHashMap)
    length(m1) == length(m2) && all(x -> x[1] == x[2], zip(m1.trie, m2.trie))
end

function assoc{K, V}(m::PersistentHashMap{K, V}, key::K, value::V)
    keyhash = int(hash(key))
    arraymap = assoc(get(m.trie, keyhash, PersistentArrayMap{K, V}()), key, value)
    newtrie, _ = update(m.trie, keyhash, arraymap)
    PersistentHashMap{K, V}(newtrie)
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

# TODO Base.has, dissoc, show 
