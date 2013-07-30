# Sparse Bitmapped Tries
# ======================

abstract SparseBitmappedTrie{T} <: BitmappedTrie{T}

immutable SparseNode{T} <: SparseBitmappedTrie{T}
    arr::Vector{SparseBitmappedTrie{T}}
    shift::Int
    length::Int
    maxlength::Int
    bitmap::Int
end
SparseNode(T::Type) = SparseNode{T}(SparseBitmappedTrie{T}[], shiftby*7, 0, trielen^7, 0)

immutable SparseLeaf{T} <: SparseBitmappedTrie{T}
    arr::Vector{T}
    bitmap::Int

    SparseLeaf(arr::Vector, bitmap::Int) = new(arr, bitmap)
    SparseLeaf() = new(T[], 0)
end

arrayof(    n::SparseNode) = n.arr
shift(      n::SparseNode) = n.shift
maxlength(  n::SparseNode) = n.maxlength
Base.length(n::SparseNode) = n.length

arrayof(    l::SparseLeaf) = l.arr
shift(       ::SparseLeaf) = 0
maxlength(  l::SparseLeaf) = trielen
Base.length(l::SparseLeaf) = length(arrayof(l))

function demoted{T}(n::SparseNode{T})
    shift(n) == shiftby ?
    SparseLeaf{T}(T[], 0) :
    SparseNode{T}(SparseBitmappedTrie{T}[],
                  shift(n) - shiftby,
                  0,
                  int(maxlength(n) / trielen), 0)
end

bitpos(  t::SparseBitmappedTrie, i::Int) = 1 << (mask(t, i) - 1)
hasindex(t::SparseBitmappedTrie, i::Int) = t.bitmap & bitpos(t, i) != 0
index(   t::SparseBitmappedTrie, i::Int) =
    1 + count_ones(t.bitmap & (bitpos(t, i) - 1))

function update{T}(l::SparseLeaf{T}, i::Int, el::T)
    hasi = hasindex(l, i)
    bitmap = bitpos(l, i) | l.bitmap
    idx = index(l, i)
    if hasi
        newarr = arrayof(l)[:]
        newarr[idx] = el
    else
        newarr = vcat(arrayof(l)[1:idx-1], [el], arrayof(l)[idx:end])
    end
    (SparseLeaf{T}(newarr, bitmap), !hasi)
end
function update{T}(n::SparseNode{T}, i::Int, el::T)
    bitmap = bitpos(n, i) | n.bitmap
    idx = index(n, i)
    if hasindex(n, i)
        newarr = arrayof(n)[:]
        updated, inc = update(newarr[idx], i, el)
        newarr[idx] = updated
    else
        child, inc = update(demoted(n), i, el)
        newarr = vcat(arrayof(n)[1:idx-1], [child], arrayof(n)[idx:end])
    end
    (SparseNode{T}(newarr,
                   n.shift,
                   inc ? n.length + 1 : n.length,
                   n.maxlength, bitmap),
     inc)
end

Base.get(n::SparseLeaf, i::Int, default) =
    hasindex(n, i) ? arrayof(n)[index(n, i)] : default
Base.get(n::SparseNode, i::Int, default) =
    hasindex(n, i) ? get(arrayof(n)[index(n, i)], i, default) : default

function Base.start(t::SparseBitmappedTrie)
    t.length == 0 && return true
    ones(Int, 1 + int(t.shift / shiftby))
end

function directindex(t::SparseBitmappedTrie, v::Vector{Int})
    isempty(v) && return arrayof(t)
    local node = arrayof(t)
    for i=v
        node = node[i]
        node = isa(node, SparseBitmappedTrie) ? arrayof(node) : node
    end
    node
end

Base.done(t::SparseBitmappedTrie, state) = state == true

function Base.next(t::SparseBitmappedTrie, state::Vector{Int})
    item = directindex(t, state)
    while true
        index = pop!(state)
        node = directindex(t, state)
        if length(node) > index
            push!(state, index + 1)
            return item, vcat(state, ones(Int, 1 + int(t.shift / shiftby) -
                                               length(state)))
        elseif is(node, arrayof(t))
            return item, true
        end
    end
end

# Persistent Hash Maps
# ====================

immutable PersistentHashMap{K, V} <: PersistentMap{K, V}
    trie::SparseBitmappedTrie{PersistentArrayMap{K, V}}
    length::Int

    PersistentHashMap(trie, length) = new(trie, length)
    PersistentHashMap() = new(SparseNode(PersistentArrayMap{K, V}), 0)
end

function PersistentHashMap(kvs::(Any, Any)...)
    K, V = typejoin(map(typeof, kvs)...)
    m = PersistentHashMap{K, V}()
    for (k, v) in kvs
        m = assoc(m, k, v)
    end
    m
end

function PersistentHashMap(; kwargs...)
    isempty(kwargs) ?
    PersistentHashMap{Any, Any}() :
    PersistentHashMap(kwargs...)
end

Base.length(m::PersistentHashMap) = m.length
Base.isempty(m::PersistentHashMap) = length(m) == 0

function Base.isequal(m1::PersistentHashMap, m2::PersistentHashMap)
    length(m1) == length(m2) && all(x -> x[1] == x[2], zip(m1.trie, m2.trie))
end

function _update{K, V}(f::Function, m::PersistentHashMap{K, V}, key)
    keyhash = int(hash(key))
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
Base.done(m::PersistentHashMap, state) =
    isempty(state[1]) && done(m.trie, state[2])

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

function Base.filter{K, V}(f::Function, m::PersistentHashMap{K, V})
    arr = Array((K, V), 0)
    for el in m
        f(el) && push!(arr, el)
    end
    isempty(arr) ? PersistentHashMap{K, V}() : PersistentHashMap(arr...)
end

function Base.show{K, V}(io::IO, m::PersistentHashMap{K, V})
    print(io, "Persistent{$K, $V}[")
    print(io, join(["$k => $v" for (k, v) in m], ", "))
    print(io, "]")
end
