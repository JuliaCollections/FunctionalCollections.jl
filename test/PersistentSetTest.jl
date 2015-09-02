using FactCheck
using FunctionalCollections

typealias PS PersistentSet

facts("Persistent Sets") do

    context("construction") do
        s = PS(1, 1, 2, 3, 3)
        @fact length(s) --> 3
        @fact length(PS{ASCIIString}()) --> 0
        @fact typeof(PS{Integer}([1,2,3])) --> PS{Integer}
        @fact typeof(PS(Integer[1,2,3])) --> PS{Integer}
    end

    context("isequal") do
        @fact PS(1, 2, 3) --> PS(1, 2, 3)
        @fact PS(1, 2, 3) --> PS(3, 2, 1)
        @fact PS{ASCIIString}() --> PS{Int}()
    end

    context("conj") do
        @fact conj(PS(1, 2, 3), 4) --> PS(1, 2, 3, 4)
        @fact conj(PS(1, 2, 3), 1) --> PS(1, 2, 3)
        @fact conj(PS(1, 2, 3), 4) --> PS(4, 3, 2, 1)
    end

    context("disj") do
        @fact disj(PS(1, 2, 3), 3) --> PS(1, 2)
        @fact disj(PS(1, 2), 3) --> PS(1, 2)
        @fact disj(PS{Int}(), 1234) --> PS{Int}()
    end

    context("in") do
        @fact "foo" in PS("foo", "bar") --> true
        @fact "baz" in PS("foo", "bar") --> false
    end

    context("filter") do
        @fact filter(iseven, PS(1, 2, 3, 4)) --> PS(2, 4)
    end

    context("setdiff, -") do
        @fact setdiff(PS(1, 2, 3), PS(1, 2)) --> PS(3)
        @fact setdiff(PS(1, 2), PS(1, 2, 3)) --> PS{Int}()
        @fact setdiff(PS(1, 2, 3), Set([1, 2])) --> PS(3)

        @fact PS(1, 2, 3) - PS(1, 2) --> PS(3)
    end

    context("isempty") do
        @fact PS{Int}() --> isempty
        @fact PS(1) --> not(isempty)
    end

    context("union") do
        @fact union(PS(1, 2, 3), PS(4, 5)) --> PS(1, 2, 3, 4, 5)
        @fact union(PS(1, 2, 3), PS(1, 2, 3, 4)) --> PS(1, 2, 3, 4)
        @fact union(PS(1), PS(2), PS(3)) --> PS(1, 2, 3)
    end

    context("isless, <=") do
        @fact PS(1)    <= PS(1, 2) --> true
        @fact PS(1, 2) <= PS(1, 2) --> true

        @fact PS(1, 2, 3) <= PS(1, 2) --> false
        @fact PS(1, 2) <= PS(1, 2, 3) --> true

        @fact isless(PS(1, 2), PS(1, 2))    --> false
        @fact isless(PS(1, 2), PS(1, 2, 3)) --> true
    end

    context("iteration") do
        @fact length([el for el in PS(1, 2, 3, 4)]) --> 4
    end

end
