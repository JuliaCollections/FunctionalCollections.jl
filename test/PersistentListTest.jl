using FunctionalCollections
using Test

@testset "Persistent Lists" begin

    @testset "length" begin
        @test length(PersistentList([1])) == 1
        @test length(PersistentList([1, 2, 3])) == 3
        @test length(EmptyList()) == 0
    end

    @testset "equality" begin
        @test PersistentList(1:100) == PersistentList(1:100)
        @test PersistentList(1:100) != PersistentList(1:99)
        @test PersistentList(1:100) == collect(1:100)
    end

    @testset "head" begin
        @test head(PersistentList(1:100)) == 1
        @test head(PersistentList([1]))   == 1
        @test try head(EmptyList()); false catch e true end
    end

    @testset "tail" begin
        @test tail(PersistentList(1:100)) == PersistentList(2:100)
        @test tail(PersistentList([1]))     == EmptyList()
        @test try tail(EmptyList()); false catch e true end
    end

    @testset "cons" begin
        @test cons(1, cons(2, cons(3, EmptyList()))) == PersistentList([1, 2, 3])
        @test 1..(2..(3..EmptyList())) == PersistentList([1, 2, 3])
    end

    @testset "sharing" begin
        l = PersistentList(1:100)
        l2 = 0..l
        @test l === tail(l2)
    end

    @testset "iteration" begin
        arr2 = Int[]
        for i in PersistentList(1:1000)
            push!(arr2, i)
        end
        @test collect(1:1000) == arr2
    end

    @testset "map" begin
        @test map(x->x+1, PersistentList([1,2,3,4,5])) == PersistentList([2,3,4,5,6])
    end

    @testset "filter" begin
        @test filter(x->x%2==0, PersistentList([1,2,3,4,5,6])) == PersistentList([2,4,6])
    end

    @testset "reverse" begin
        @test reverse(PersistentList(1:10)) == 10:-1:1
    end

    @testset "hash" begin
        @test hash(PersistentList(1:1000)) == hash(PersistentList(1:1000))
    end

    @testset "isempty" begin
        @test isempty(EmptyList())
        @test !isempty(PersistentList([1]))
    end

end
