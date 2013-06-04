using FunctionalCollections
using FactCheck

function vec(r::Range1)
    v = PersistentVector{Int}()
    for i=r v=append(v, i) end
    v
end

function Base.Array(r::Range1)
    arr = Array(Int, r)
    for i=r arr[i] = i end
    arr
end

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

    @fact "associng" begin
        assoc(vec(1:1000), 500, 1)[500] => 1
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

    @fact "equality" begin
        v1 = vec(1:1000)
        v2 = vec(1:1000)

        is(v1.trie, v2.trie) => false
        v1 => v2

        isequal(v1, v2) => true
    end

    @fact "iteration" begin
        arr2 = Int[]
        for i in vec(1:10000)
            push!(arr2, i)
        end
        1:10000 => arr2
    end

    @fact "map" begin
        v1 = vec(1:5)
        map((x)->x+1, v1) => PersistentVector([2, 3, 4, 5, 6])
    end

    @fact "hash" begin
        hash(vec(1:1000)) => hash(vec(1:1000))
    end

    @fact "isempty" begin
        PersistentVector{Int}() => isempty
        PersistentVector([1])   => not(isempty)
    end

end
