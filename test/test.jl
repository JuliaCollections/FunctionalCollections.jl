using FactCheck
using PersistentDataStructures

function transient(r::Range1)
    tv = TransientVector{Int}()
    for i=r push!(tv, i) end
    tv
end

function Base.Array(r::Range1)
    arr = Array(Int, r)
    for i=r arr[i] = i end
    arr
end

@facts "Transient Vectors" begin

    @fact "length" begin
        length(transient(1:32)) => 32
        length(transient(1:10000)) => 10000
    end

    @fact "accessing elements" begin
        tv = transient(1:5000)

        tv[1]    => 1
        tv[32]   => 32
        tv[500]  => 500
        tv[2500] => 2500
        tv[5000] => 5000
        tv[5001] => :throws

        transient(1:32)[33] => :throws
    end

    @fact "updating" begin
        tv = transient(1:5000)

        (tv[1000] = 1) => 1
        tv[1000] => 1
    end

    @fact "transient => persistent" begin
        tv = TransientVector{Int}()
        push!(tv, 1)
        length(tv) => 1

        pv = persist!(tv)
        typeof(pv) => PersistentVector{Int}

        # Cannot mutate transient after call to persist!
        push!(tv, 2) => :throws

        tv = transient(1:1000)
        typeof(tv.trie) => PersistentDataStructures.TransientBitmappedTrie
        pv = persist!(tv)
        typeof(pv.trie) => PersistentDataStructures.BitmappedTrie
        tv.persistent => true
    end

end

vec(r::Range1) = persist!(transient(r))

@facts "Persistent Vectors" begin

    @fact "range constructor" begin
        typeof(vec(1:1000)) => PersistentVector{Int}
        typeof(pop(vec(1:1000))) => PersistentVector{Int}
    end

    @fact "length" begin
        length(vec(1:32)) => 32
        length(vec(1:10000)) => 10000
        length(pop(vec(1:1000))) => 999
    end

    @fact "accessing elements" begin
        pv = vec(1:5000)

        pv[1]    => 1
        pv[32]   => 32
        pv[500]  => 500
        pv[2500] => 2500
        pv[5000] => 5000
        pv[5001] => :throws

        vec(1:32)[33] => :throws
    end

    @fact "accessing last" begin
        peek(vec(1:1000)) => 1000
        vec(1:1000)[end]  => 1000
    end

    @fact "updating" begin
        update(vec(1:1000), 500, 1)[500] => 1
    end

    @fact "appending" begin
        append(vec(1:31), 32)        => vec(1:32)
        append(vec(1:999), 1000)     => vec(1:1000)
        append(vec(1:9999), 10000)   => vec(1:10000)
        append(vec(1:99999), 100000) => vec(1:100000)
    end

    @fact "structural sharing" begin
        pv = vec(1:32)
        pv2 = append(pv, 33)
        is(pv2.trie[1], pv.tail) => true
    end

    @fact "Base.==" begin
        v1 = vec(1:1000)
        v2 = vec(1:1000)

        is(v1.trie, v2.trie) => false
        v1 => v2
    end

    @fact "iteration" begin
        arr2 = Int[]
        for i in vec(1:10000)
            push!(arr2, i)
        end
        1:10000 => arr2
    end

    @fact "Base.map" begin
        v1 = vec(1:5)
        map((x)->x+1, v1) => PersistentVector([2, 3, 4, 5, 6])
    end

    @fact "Base.hash" begin
        hash(vec(1:1000)) => hash(vec(1:1000))
    end

end
