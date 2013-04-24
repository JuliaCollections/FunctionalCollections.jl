using FactCheck
using PersistentDataStructures

import PersistentDataStructures: SparseBitmappedTrie,
    SparseNode, SparseLeaf, bitpos, index, hasindex

@facts "Sparse Bitmapped Vector Tries" begin

    @fact "bitpos and index" begin
        l = SparseLeaf{Int}([6, 11, 16, 21, 26],
                            2^5 | 2^10 | 2^15 | 2^20 | 2^25)
        index(l, 6) => 1
        index(l, 11) => 2
        index(l, 16) => 3
        index(l, 21) => 4
        index(l, 26) => 5

        hasindex(l, 5)  => false
        hasindex(l, 6)  => true
        hasindex(l, 7)  => false
        hasindex(l, 11) => true
        hasindex(l, 12) => false
        hasindex(l, 21) => true
    end

    @fact "SparseLeaf update" begin
        l = SparseLeaf{Int}()

        update(l, 1, 1)   => (leaf) -> hasindex(leaf[1], 1)
        update(l, 10, 10) => (leaf) -> hasindex(leaf[1], 10) &&
                                            !hasindex(leaf[1], 11)

        l = SparseLeaf{Int}([1, 5], 2^0 | 2^4)
        l, _ = update(l, 2, 2)
        l.self => [1, 2, 5]
        length(l) => 3
        hasindex(l, 1) => true
        hasindex(l, 2) => true
        hasindex(l, 3) => false
        hasindex(l, 4) => false
        hasindex(l, 5) => true
        hasindex(l, 6) => false

        update(l, 2, 100)[1].self => [1, 100, 5]
    end

    @fact "SparseNode update" begin
        n, _ = update(SparseNode(ASCIIString), 1, "foo")
        length(n.self) => 1

        leaf = n.self[1].self[1].self[1].self[1].self[1].self[1].self[1]
        hasindex(leaf, 1) => true
        leaf.self[1] => "foo"

        n2, _ = update(n, 33, "bar")
        leaf2 = n2.self[1].self[1].self[1].self[1].self[1].self[1].self[2]
        hasindex(leaf2, 33) => true
        leaf2.self[1] => "bar"
    end

    @fact "SparseBitmappedTrie get" begin
        n, _ = update(SparseNode(Int), 33, 33)
        get(n, 33, "missing") => 33
        get(update(SparseNode(Int), 12345, 12345)[1], 12345, "missing") => 12345
        get(n, 12345, "missing") => "missing"
    end

    @fact "SparseBitmappedTrie length" begin
        n = SparseNode(Int)
        for i=1:1000
            n, _ = update(n, i, i)
        end
        length(n) => 1000
    end

    @fact "SparseBitmappedTrie items" begin
        n = SparseNode(Int)
        for i=1:1000
            n, _ = update(n, i, i)
        end
        [i for i=n] => 1:1000
    end

end
