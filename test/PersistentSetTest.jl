using FunctionalCollections
using Test

const PS = PersistentSet

@testset "Persistent Sets" begin

    @testset "construction" begin
        s = PS([1, 1, 2, 3, 3])
        @test length(s) == 3
        @test length(PS{String}()) == 0
        @test typeof(PS{Int64}([1,2,3])) == PS{Int64}
        @test typeof(PS(Int64[1,2,3])) == PS{Int64}
    end

    @testset "isequal" begin
        @test PS([1, 2, 3]) == PS([1, 2, 3])
        @test PS([1, 2, 3]) == PS([3, 2, 1])
        @test PS{String}() == PS{Int}()
    end

    @testset "conj" begin
        @test conj(PS([1, 2, 3]), 4) == PS([1, 2, 3, 4])
        @test conj(PS([1, 2, 3]), 1) == PS([1, 2, 3])
        @test conj(PS([1, 2, 3]), 4) == PS([4, 3, 2, 1])
    end

    @testset "disj" begin
        @test disj(PS([1, 2, 3]), 3) == PS([1, 2])
        @test disj(PS([1, 2]), 3) == PS([1, 2])
        @test disj(PS{Int}(), 1234) == PS{Int}()
    end

    @testset "in" begin
        @test "foo" in PS(["foo", "bar"])
        @test !("baz" in PS(["foo", "bar"]))
    end

    @testset "filter" begin
        @test filter(iseven, PS([1, 2, 3, 4])) == PS([2, 4])
    end

    @testset "setdiff, -" begin
        @test setdiff(PS([1, 2, 3]), PS([1, 2])) == PS([3])
        @test setdiff(PS([1, 2]), PS([1, 2, 3])) == PS{Int}()
        @test setdiff(PS([1, 2, 3]), Set([1, 2])) == PS([3])

        @test PS([1, 2, 3]) - PS([1, 2]) == PS([3])
    end

    @testset "isempty" begin
        @test isempty(PS{Int}())
        @test !isempty(PS([1]))
    end

    @testset "union" begin
        @test union(PS([1, 2, 3]), PS([4, 5])) == PS([1, 2, 3, 4, 5])
        @test union(PS([1, 2, 3]), PS([1, 2, 3, 4])) == PS([1, 2, 3, 4])
        @test union(PS([1]), PS([2]), PS([3])) == PS([1, 2, 3])
    end

    @testset "isless, <=" begin
        @test PS([1])    <= PS([1, 2])
        @test PS([1, 2]) <= PS([1, 2])

        @test !(PS([1, 2, 3]) <= PS([1, 2]))
        @test PS([1, 2]) <= PS([1, 2, 3])

        @test !isless(PS([1, 2]), PS([1, 2]))
        @test isless(PS([1, 2]), PS([1, 2, 3]))
    end

    @testset "iteration" begin
        @test length([el for el in PS([1, 2, 3, 4])]) == 4
    end

end
