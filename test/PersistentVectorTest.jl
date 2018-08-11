using FunctionalCollections
using Test
import Base.vec

function vec(r::UnitRange)
    v = PersistentVector{Int}()
    for i in r
      v = push(v, i)
    end
    v
end

function Base.Array(r::UnitRange)
    arr = Array(Int, r)
    for i in r
      arr[i] = i
    end
    arr
end

@testset "Persistent Vectors" begin

    @testset "range constructor" begin
        @test typeof(vec(1:1000)) == PersistentVector{Int}
        @test typeof(pop(vec(1:1000))) == PersistentVector{Int}
    end

    @testset "length" begin
        @test length(vec(1:32)) == 32
        @test length(vec(1:10000)) == 10000
        @test length(pop(vec(1:1000))) == 999
    end

    @testset "accessing elements" begin
        pv = vec(1:5000)
        @test length(pv) == lastindex(pv) == 5000

        @test pv[1]    == 1
        @test pv[32]   == 32
        @test pv[500]  == 500
        @test pv[2500] == 2500
        @test pv[5000] == 5000
        @test try pv[5001]; false catch e true end

        @test try vec(1:32)[33]; false catch e true end
    end

    @testset "accessing last" begin
        @test peek(vec(1:1000)) == 1000
        @test vec(1:1000)[end]  == 1000
    end

    @testset "associng" begin
        @test assoc(vec(1:1000), 500, 1)[500] == 1
    end

    @testset "appending" begin
        # inference problems in 0.5.0, seem fixed in 0.6.0-dev
        @test append(vec(1:31), 32)        == vec(1:32)
        @test append(vec(1:999), 1000)     == vec(1:1000)
        @test append(vec(1:9999), 10000)   == vec(1:10000)
        @test append(vec(1:99999), 100000) == vec(1:100000)
    end

    @testset "structural sharing" begin
        pv = vec(1:32)
        @test length(pv) == lastindex(pv) == 32
        pv2 = append(pv, 33)
        @test length(pv2) == lastindex(pv2) == 33
        @test pv2.trie[1] === pv.tail
    end

    @testset "equality" begin
        v1 = vec(1:1000)
        v2 = vec(1:1000)

        @test v1.trie !== v2.trie
        @test v1 == v2

        @test isequal(v1, v2)
    end

    @testset "iteration" begin
        arr2 = Int[]
        for i in vec(1:10000)
            push!(arr2, i)
        end
        @test collect(1:10000) == arr2
    end

    @testset "map" begin
        v1 = vec(1:5)
        @test map((x)->x+1, v1) == PersistentVector([2, 3, 4, 5, 6])
        v2 = PersistentVector{Tuple{Int,Int}}([(1,2),(4,3)])
        @test map((x)->(x[2],x[1]), v2) == PersistentVector{Tuple{Int,Int}}([(2,1),(3,4)])
    end

    @testset "filter" begin
        v1 = vec(1:5)
        @test filter(iseven, v1) == PersistentVector([2, 4])
        v2 = PersistentVector{Tuple{Int,Int}}([(1,2),(4,3)])
        @test filter((x)->x[2] > x[1], v2) == PersistentVector{Tuple{Int,Int}}([(1,2)])
    end

    @testset "hash" begin
        @test hash(vec(1:1000)) == hash(vec(1:1000))
    end

    @testset "isempty" begin
        @test isempty(PersistentVector{Int}())
        @test !isempty(PersistentVector([1]))
    end

end
