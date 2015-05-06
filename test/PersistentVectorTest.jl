using FunctionalCollections
using FactCheck

function vec(r::UnitRange)
    v = PersistentVector{Int}()
    for i=r v=push(v, i) end
    v
end

function Base.Array(r::UnitRange)
    arr = Array(Int, r)
    for i=r arr[i] = i end
    arr
end

facts("Persistent Vectors") do

    context("range constructor") do
        @fact typeof(vec(1:1000)) => PersistentVector{Int}
        @fact typeof(pop(vec(1:1000))) => PersistentVector{Int}
    end

    context("length") do
        @fact length(vec(1:32)) => 32
        @fact length(vec(1:10000)) => 10000
        @fact length(pop(vec(1:1000))) => 999
    end

    context("accessing elements") do
        pv = vec(1:5000)

        @fact pv[1]    => 1
        @fact pv[32]   => 32
        @fact pv[500]  => 500
        @fact pv[2500] => 2500
        @fact pv[5000] => 5000
        @fact try pv[5001]; false catch e true end => true

        @fact try vec(1:32)[33]; false catch e true end => true
    end

    context("accessing last") do
        @fact peek(vec(1:1000)) => 1000
        @fact vec(1:1000)[end]  => 1000
    end

    context("associng") do
        @fact assoc(vec(1:1000), 500, 1)[500] => 1
    end

    context("appending") do
        @fact append(vec(1:31), 32)        => vec(1:32)
        @fact append(vec(1:999), 1000)     => vec(1:1000)
        @fact append(vec(1:9999), 10000)   => vec(1:10000)
        @fact append(vec(1:99999), 100000) => vec(1:100000)
    end

    context("structural sharing") do
        pv = vec(1:32)
        pv2 = append(pv, 33)
        @fact is(pv2.trie[1], pv.tail) => true
    end

    context("equality") do
        v1 = vec(1:1000)
        v2 = vec(1:1000)

        @fact is(v1.trie, v2.trie) => false
        @fact v1 => v2

        @fact isequal(v1, v2) => true
    end

    context("iteration") do
        arr2 = Int[]
        for i in vec(1:10000)
            push!(arr2, i)
        end
        @fact collect(1:10000) => arr2
    end

    context("map") do
        v1 = vec(1:5)
        @fact map((x)->x+1, v1) => PersistentVector([2, 3, 4, 5, 6])
    end

    context("filter") do
        v1 = vec(1:5)
        @fact filter(iseven, v1) => PersistentVector([2, 4])
    end

    context("hash") do
        @fact hash(vec(1:1000)) => hash(vec(1:1000))
    end

    context("isempty") do
        @fact PersistentVector{Int}() => isempty
        @fact PersistentVector([1])   => not(isempty)
    end

end
