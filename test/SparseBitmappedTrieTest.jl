using FactCheck
using FunctionalCollections

import FunctionalCollections: SparseBitmappedTrie, SparseNode, SparseLeaf,
    bitpos, index, hasindex, arrayof, update

facts("Sparse Bitmapped Vector Tries") do

    context("bitpos and index") do
        l = SparseLeaf{Int}([6, 11, 16, 21, 26],
                            2^5 | 2^10 | 2^15 | 2^20 | 2^25)
        @fact index(l, 6) --> 1
        @fact index(l, 11) --> 2
        @fact index(l, 16) --> 3
        @fact index(l, 21) --> 4
        @fact index(l, 26) --> 5

        @fact hasindex(l, 5)  --> false
        @fact hasindex(l, 6)  --> true
        @fact hasindex(l, 7)  --> false
        @fact hasindex(l, 11) --> true
        @fact hasindex(l, 12) --> false
        @fact hasindex(l, 21) --> true
    end

    context("SparseLeaf update") do
        l = SparseLeaf{Int}()

        @fact update(l, 1, 1)   --> (leaf) -> hasindex(leaf[1], 1)
        @fact update(l, 10, 10) --> (leaf) -> hasindex(leaf[1], 10) &&
                                             !hasindex(leaf[1], 11)

        l = SparseLeaf{Int}([1, 5], 2^0 | 2^4)
        l, _ = update(l, 2, 2)
        @fact arrayof(l) --> [1, 2, 5]
        @fact length(l) --> 3
        @fact hasindex(l, 1) --> true
        @fact hasindex(l, 2) --> true
        @fact hasindex(l, 3) --> false
        @fact hasindex(l, 4) --> false
        @fact hasindex(l, 5) --> true
        @fact hasindex(l, 6) --> false

        @fact arrayof(update(l, 2, 100)[1]) --> [1, 100, 5]
    end

    context("SparseNode update") do
        n, _ = update(SparseNode(ASCIIString), 1, "foo")
        @fact length(arrayof(n)) --> 1

        leaf = arrayof(n)[1].arr[1].arr[1].arr[1].arr[1].arr[1].arr[1]
        @fact hasindex(leaf, 1) --> true
        @fact leaf.arr[1] --> "foo"

        n2, _ = update(n, 33, "bar")
        leaf2 = n2.arr[1].arr[1].arr[1].arr[1].arr[1].arr[1].arr[2]
        @fact hasindex(leaf2, 33) --> true
        @fact arrayof(leaf2)[1] --> "bar"
    end

    context("SparseBitmappedTrie get") do
        n, _ = update(SparseNode(Int), 33, 33)
        @fact get(n, 33, "missing") --> 33
        @fact get(update(SparseNode(Int), 12345, 12345)[1], 12345, "missing") --> 12345
        @fact get(n, 12345, "missing") --> "missing"
    end

    context("SparseBitmappedTrie length") do
        n = SparseNode(Int)
        for i=1:1000
            n, _ = update(n, i, i)
        end
        @fact length(n) --> 1000
    end

    context("SparseBitmappedTrie items") do
        n = SparseNode(Int)
        for i=1:1000
            n, _ = update(n, i, i)
        end
        @fact [i for i=n] --> collect(1:1000)
    end

end
