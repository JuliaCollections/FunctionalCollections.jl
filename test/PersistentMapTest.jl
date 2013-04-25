using PersistentDataStructures
using FactCheck

import PersistentDataStructures.KVPair

@facts "Persistent Maps" begin

    @fact "KVPairs" begin
        KVPair(1, 1) => (1, 1)
        (1, 1) => KVPair(1, 1)
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

    @fact "kwargs construction" begin
        PAM(x=1, y=2, z=3) => PAM((:x, 1), (:y, 2), (:z, 3))
    end

    @fact "map" begin
        m = PAM((1, 1), (2, 2), (3, 3))

        map((kv) -> (kv[1], kv[2]+1), m) => PAM((1, 2), (2, 3), (3, 4))
    end
end


typealias PHM PersistentHashMap
@facts "PersistentHashMap" begin

    @fact "constructor" begin
        hashmap = PHM{Int, Int}()
        length(hashmap) => 0
        length(PHM((1, 1), (2, 2), (3, 3))) => 3
        length(PHM(x=1, y=2, z=3)) => 3
    end

    @fact "equality" begin
        PHM{Int, Int}() => PHM{Int, Int}()
        PHM{Int, Int}() => PHM{String, String}()

        m1 = PHM{Int, Int}()
        m2 = PHM{Int, Int}()
        assoc(m1, 1, 100) => assoc(m2, 1, 100)
        assoc(m1, 1, 100) => not(assoc(m2, 1, 200))
        assoc(m1, 1, 100) => not(assoc(m2, 2, 100))

        m3 = PHM((1, 10), (2, 20), (3, 30))
        m4 = PHM((3, 30), (2, 20), (1, 10))
        m3 => m4
        m3 => not(m1)
    end

    @fact "assoc" begin
        m = PHM{Int, ASCIIString}()
        assoc(m, 1, "one") => (m) -> m[1] == "one"
        m[1] => :throws

        m = PHM{Int, ASCIIString}()
        m = assoc(m, 1, "one")
        assoc(m, 1, "foo") => (m) -> m[1] == "foo"
    end

    @fact "dissoc" begin
        m = PAM((1, "one"))
        m = dissoc(m, 1)
        m[1] => :throws
    end

    @fact "get" begin
        m = PHM{Int, ASCIIString}()
        get(m, 1, "default") => "default"
        m = assoc(m, 1, "one")
        get(m, 1, "default") => "one"
        m = assoc(m, 1, "newone")
        get(m, 1, "default") => "newone"
        get(m, 2) => :throws
    end

    @fact "has" begin
        m = PHM{Int, ASCIIString}()
        has(m, 1) => false
        m = assoc(m, 1, "one")
        has(m, 1) => true
        has(m, 2) => false
    end


end
