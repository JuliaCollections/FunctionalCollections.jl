using FactCheck
using PersistentDataStructures

typealias PS PersistentSet

@facts "Persistent Sets" begin

    @fact "construction" begin
        s = PS(1, 1, 2, 3, 3)
        length(s) => 3
        length(PS{ASCIIString}()) => 0
    end

    @fact "isequal" begin
        PS(1, 2, 3) => PS(1, 2, 3)
        PS(1, 2, 3) => PS(3, 2, 1)
        PS{ASCIIString}() => PS{Int}()
    end

    @fact "conj" begin
        conj(PS(1, 2, 3), 4) => PS(1, 2, 3, 4)
        conj(PS(1, 2, 3), 1) => PS(1, 2, 3)
        conj(PS(1, 2, 3), 4) => PS(4, 3, 2, 1)
    end

    @fact "disj" begin
        disj(PS(1, 2, 3), 3) => PS(1, 2)
        disj(PS(1, 2), 3) => PS(1, 2)
        disj(PS{Int}(), 1234) => PS{Int}()
    end

    @fact "contains" begin
        contains(PS("foo", "bar"), "foo") => true
        contains(PS("foo", "bar"), "baz") => false
    end

    @fact "filter" begin
        filter(iseven, PS(1, 2, 3, 4)) => PS(2, 4)
    end

    @fact "setdiff, -" begin
        setdiff(PS(1, 2, 3), PS(1, 2)) => PS(3)
        setdiff(PS(1, 2), PS(1, 2, 3)) => PS{Int}()
        setdiff(PS(1, 2, 3), Set(1, 2)) => PS(3)

        PS(1, 2, 3) - PS(1, 2) => PS(3)
    end

    @fact "isempty" begin
        PS{Int}() => isempty
        PS(1) => not(isempty)
    end

    @fact "union" begin
        union(PS(1, 2, 3), PS(4, 5)) => PS(1, 2, 3, 4, 5)
        union(PS(1, 2, 3), PS(1, 2, 3, 4)) => PS(1, 2, 3, 4)
        union(PS(1), PS(2), PS(3)) => PS(1, 2, 3)
    end

    @fact "isless, <=" begin
        PS(1)    <= PS(1, 2) => true
        PS(1, 2) <= PS(1, 2) => true

        PS(1, 2, 3) <= PS(1, 2) => false
        PS(1, 2) <= PS(1, 2, 3) => true

        isless(PS(1, 2), PS(1, 2))    => false
        isless(PS(1, 2), PS(1, 2, 3)) => true
    end

    @fact "iteration" begin
        length([el for el in PS(1, 2, 3, 4)]) => 4
    end

end
