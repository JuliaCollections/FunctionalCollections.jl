using FunctionalCollections
using Test

@testset "Persistent Queues" begin

    @testset "equality" begin
        @test PersistentQueue(1:100) == PersistentQueue(1:100)
        @test PersistentQueue(1:100) != (PersistentQueue(1:99))
    end

    @testset "isempty" begin
        @test isempty(PersistentQueue{Int}())
        @test !isempty(PersistentQueue([1]))
    end

    @testset "pop" begin
        @test pop(PersistentQueue(1:100)) == 100
        @test try pop(PersistentQueue{Int}()); false catch e true end
    end

    @testset "butlast" begin
        @test butlast(PersistentQueue(1:100)) == PersistentQueue(1:99)
        @test try butlast(PersistentQueue{Int}()); false catch e true end
    end

    @testset "enq" begin
        q = PersistentQueue{Int}()
        @test pop(enq(q, 1)) == 1
        @test pop(butlast(butlast(enq(enq(enq(q, 1), 2), 3)))) == 3
    end

    @testset "iteration" begin
        arr2 = Int[]
        for i in PersistentQueue(1:1000)
            push!(arr2, i)
        end
        @test arr2 == collect(1000:-1:1)
    end

    @testset "hash" begin
        @test hash(PersistentQueue(1:1000)) == hash(PersistentQueue(1:1000))
    end

    @testset "length" begin
        @test length(PersistentQueue([1, 2, 3])) == 3
        @test length(PersistentQueue{Int}()) == 0

        @test length(butlast(PersistentQueue([1, 2, 3]))) == 2
    end

end
