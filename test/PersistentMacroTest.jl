using FunctionalCollections
using Test

@testset "@Persistent constructor macro" begin

    @testset "Persistent Vectors" begin
        @test @Persistent([1, 2, 3]) == pvec([1, 2, 3])
    end

    @testset "Persistent Hash Maps" begin
        @test @Persistent(Dict("foo" => 1, "bar" => 2)) == phmap(("foo", 1), ("bar", 2))
    end

    @testset "Persistent Set" begin
        @test @Persistent(Set([1, 2, 3, 3])) == pset([1, 2, 3, 3])
    end

end
