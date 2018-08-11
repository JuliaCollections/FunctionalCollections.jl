using FunctionalCollections
using Test

import FunctionalCollections: SparseBitmappedTrie, SparseNode, SparseLeaf,
    bitpos, index, hasindex, arrayof, update

@testset "Sparse Bitmapped Vector Tries" begin

    @testset "bitpos and index" begin
        l = SparseLeaf{Int}([6, 11, 16, 21, 26],
                            2^5 | 2^10 | 2^15 | 2^20 | 2^25)
        @test index(l, 6) == 1
        @test index(l, 11) == 2
        @test index(l, 16) == 3
        @test index(l, 21) == 4
        @test index(l, 26) == 5

        @test !hasindex(l, 5)
        @test hasindex(l, 6)
        @test !hasindex(l, 7)
        @test hasindex(l, 11)
        @test !hasindex(l, 12)
        @test hasindex(l, 21)
    end

    @testset "SparseLeaf update" begin
        l = SparseLeaf{Int}()

        @test hasindex(update(l, 1, 1)[1], 1)
        l = update(l, 10, 10)
        @test hasindex(l[1], 10) && !hasindex(l[1], 11)

        l = SparseLeaf{Int}([1, 5], 2^0 | 2^4)
        l, _ = update(l, 2, 2)
        @test arrayof(l) == [1, 2, 5]
        @test length(l) == 3
        @test hasindex(l, 1)
        @test hasindex(l, 2)
        @test !hasindex(l, 3)
        @test !hasindex(l, 4)
        @test hasindex(l, 5)
        @test !hasindex(l, 6)

        @test arrayof(update(l, 2, 100)[1]) == [1, 100, 5]
    end

    @testset "SparseNode update" begin
        n, _ = update(SparseNode(String), 1, "foo")
        @test length(arrayof(n)) == 1

        leaf = arrayof(n)[1].arr[1].arr[1].arr[1].arr[1].arr[1].arr[1]
        @test hasindex(leaf, 1)
        @test leaf.arr[1] == "foo"

        n2, _ = update(n, 33, "bar")
        leaf2 = n2.arr[1].arr[1].arr[1].arr[1].arr[1].arr[1].arr[2]
        @test hasindex(leaf2, 33)
        @test arrayof(leaf2)[1] == "bar"
    end

    @testset "SparseBitmappedTrie get" begin
        n, _ = update(SparseNode(Int), 33, 33)
        @test get(n, 33, "missing") == 33
        @test get(update(SparseNode(Int), 12345, 12345)[1], 12345, "missing") == 12345
        @test get(n, 12345, "missing") == "missing"
    end

    @testset "SparseBitmappedTrie length & items" begin
        n = SparseNode(Int)
        for i=1:1000
            n, _ = update(n, i, i)
        end
        @test lastindex(n) == length(n) == 1000
        @test [i for i=n] == collect(1:1000)
    end

end
