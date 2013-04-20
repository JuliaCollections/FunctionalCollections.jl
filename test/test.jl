using FactCheck
using PersistentDataStructures

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

typealias PAM PersistentArrayMap

@facts "Persistent Array Maps" begin

    @fact "construction" begin
        length(PAM{Int, Int}().kvs) => 0
        length(PAM((1, 1), (2, 2)).kvs) => 2

        length(PAM((1, 1))) => 1
        length(PAM((1, 1), (2, 2))) => 2
    end

    @fact "accessing" begin
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        m[1] => "one"
        m[2] => "two"
        m[3] => "three"

        get(m, 1) => "one"
        get(m, 1, "foo") => "one"
        get(m, 4, "foo") => "foo"
    end

    @fact "has" begin
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        has(m, 1) => true
        has(m, 2) => true
        has(m, 3) => true
        has(m, 4) => false
    end

    @fact "assoc" begin
        m = PAM{Int, ASCIIString}()
        assoc(m, 1, "one") => (m) -> m[1] == "one"
        m[1] => :throws

        m = PAM((1, "one"))
        assoc(m, 1, "foo") => (m) -> m[1] == "foo"
    end

    @fact "dissoc" begin
        m = PAM((1, "one"))
        m = dissoc(m, 1)
        m[1] => :throws
    end

    @fact "iterating" begin
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        [v for (k, v) in m] => ["one", "two", "three"]
    end

    @fact "isempty" begin
        PAM{Int, Int}() => isempty
        PAM((1, "one")) => not(isempty)
    end

    @fact "equality" begin
        PAM((1, "one")) => PAM((1, "one"))
        PAM((1, "one"), (2, "two")) => PAM((2, "two"), (1, "one"))
        isequal(PAM((1, "one")), PAM((1, "one"))) => true

        PAM((1, "one")) => not(PAM((2, "two")))
    end

    @fact "map" begin
        m = PAM((1, 1), (2, 2), (3, 3))

        map((kv) -> (kv[1], kv[2]+1), m) => PAM((1, 2), (2, 3), (3, 4))
    end
end
