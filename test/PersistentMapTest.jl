using Compat
using FunctionalCollections
using FactCheck

import FunctionalCollections.KVPair

facts("Persistent Maps") do

    context("KVPairs") do
        @fact KVPair(1, 1) --> (1, 1)
        @fact (1, 1) --> KVPair(1, 1)
    end

end

typealias PAM PersistentArrayMap

facts("Persistent Array Maps") do

    context("construction") do
        @fact length(PAM{Int, Int}().kvs) --> 0
        @fact length(PAM((1, 1), (2, 2)).kvs) --> 2

        @fact length(PAM((1, 1))) --> 1
        @fact length(PAM((1, 1), (2, 2))) --> 2
    end

    context("accessing") do
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        @fact m[1] --> "one"
        @fact m[2] --> "two"
        @fact m[3] --> "three"

        @fact get(m, 1) --> "one"
        @fact get(m, 1, "foo") --> "one"
        @fact get(m, 4, "foo") --> "foo"
    end

    context("haskey") do
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        @fact haskey(m, 1) --> true
        @fact haskey(m, 2) --> true
        @fact haskey(m, 3) --> true
        @fact haskey(m, 4) --> false
    end

    context("assoc") do
        m = PAM{Int, ASCIIString}()
        @fact assoc(m, 1, "one") --> (m) -> m[1] == "one"
        @fact try m[1]; false catch e true end --> true

        m = PAM((1, "one"))
        @fact assoc(m, 1, "foo") --> (m) -> m[1] == "foo"
    end

    context("dissoc") do
        m = PAM((1, "one"))
        m = dissoc(m, 1)
        @fact try m[1]; false catch e true end --> true

        m = PAM((1, "one"), (2, "two"))
        @fact dissoc(m, 1) --> PAM((2, "two"))
    end

    context("iterating") do
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        @fact [v for (k, v) in m] --> ["one", "two", "three"]
    end

    context("isempty") do
        @fact PAM{Int, Int}() --> isempty
        @fact PAM((1, "one")) --> not(isempty)
    end

    context("equality") do
        @fact PAM((1, "one")) --> PAM((1, "one"))
        @fact PAM((1, "one"), (2, "two")) --> PAM((2, "two"), (1, "one"))
        @fact isequal(PAM((1, "one")), PAM((1, "one"))) --> true

        @fact PAM((1, "one")) --> not(PAM((2, "two")))
    end

    context("kwargs construction") do
        @fact PAM(x=1, y=2, z=3) --> PAM((:x, 1), (:y, 2), (:z, 3))
    end

    context("map") do
        m = PAM((1, 1), (2, 2), (3, 3))

        @fact map((kv) -> (kv[1], kv[2]+1), m) --> PAM((1, 2), (2, 3), (3, 4))
    end
end

typealias PHM PersistentHashMap

facts("Persistent Hash Maps") do

    context("constructor") do
        hashmap = PHM{Int, Int}()
        @fact length(hashmap) --> 0
        @fact length(PHM((1, 1), (2, 2), (3, 3))) --> 3
        @fact length(PHM(x=1, y=2, z=3)) --> 3
    end

    context("equality") do
        @fact PHM{Int, Int}() --> PHM{Int, Int}()
        @fact PHM{Int, Int}() --> PHM{String, String}()

        m1 = PHM{Int, Int}()
        m2 = PHM{Int, Int}()
        @fact assoc(m1, 1, 100) --> assoc(m2, 1, 100)
        @fact assoc(m1, 1, 100) --> not(assoc(m2, 1, 200))
        @fact assoc(m1, 1, 100) --> not(assoc(m2, 2, 100))

        m3 = PHM((1, 10), (2, 20), (3, 30))
        m4 = PHM((3, 30), (2, 20), (1, 10))
        @fact m3 --> m4
        @fact m3 --> not(m1)

        @fact m3 --> (@compat Dict(1 => 10, 2 => 20, 3 => 30))
    end

    context("assoc") do
        m = PHM{Int, ASCIIString}()
        @fact assoc(m, 1, "one") --> (m) -> m[1] == "one"
        @fact try m[1]; false catch e true end --> true

        m = PHM{Int, ASCIIString}()
        m = assoc(m, 1, "one")
        @fact assoc(m, 1, "foo") --> (m) -> m[1] == "foo"
    end

    context("covariance") do
        m = PHM{Any, Any}()
        @fact assoc(m, "foo", "bar") --> (@compat Dict("foo" => "bar"))
    end

    context("dissoc") do
        m = PAM((1, "one"))
        m = dissoc(m, 1)
        @fact try m[1]; false catch e true end --> true

        m = PHM((1, "one"), (2, "two"))
        @fact dissoc(m, 1) --> PHM((2, "two"))
    end

    context("get") do
        m = PHM{Int, ASCIIString}()
        @fact get(m, 1, "default") --> "default"
        m = assoc(m, 1, "one")
        @fact get(m, 1, "default") --> "one"
        m = assoc(m, 1, "newone")
        @fact get(m, 1, "default") --> "newone"
        @fact try get(m, 2); false catch e true end --> true
    end

    context("haskey") do
        m = PHM{Int, ASCIIString}()
        @fact haskey(m, 1) --> false
        m = assoc(m, 1, "one")
        @fact haskey(m, 1) --> true
        @fact haskey(m, 2) --> false
    end

    context("map") do
        m = PHM((1, 1), (2, 2), (3, 3))
        @fact map((kv) -> (kv[1], kv[2]+1), m) --> PHM((1, 2), (2, 3), (3, 4))
    end

    context("filter") do
        @fact filter((kv) -> iseven(kv[2]), PHM((1, 1), (2, 2))) --> PHM((2, 2))
    end

    context("merge") do
        @fact merge(PHM((1, 1), (2, 2)), PHM((2, 3), (3, 4))) -->
                PHM((1,1), (2, 3), (3, 4))
    end
end
