using FunctionalCollections
using FactCheck

@facts "Persistent Lists" begin

    @fact "length" begin
        length(PersistentList([1])) => 1
        length(PersistentList([1, 2, 3])) => 3
        length(EmptyList()) => 0
    end

    @fact "equality" begin
        PersistentList([1:100]) => PersistentList([1:100])
        PersistentList([1:100]) => not(PersistentList([1:99]))
        PersistentList([1:100]) => [1:100]
    end

    @fact "head" begin
        head(PersistentList([1:100])) => 1
        head(PersistentList([1]))     => 1
        head(EmptyList())   => :throws
    end

    @fact "tail" begin
        tail(PersistentList([1:100])) => PersistentList([2:100])
        tail(PersistentList([1]))     => EmptyList()
        tail(EmptyList())   => :throws
    end

    @fact "cons" begin
        cons(1, cons(2, cons(3, EmptyList()))) => PersistentList([1, 2, 3])
        1..(2..(3..EmptyList())) => PersistentList([1, 2, 3])
    end

    @fact "sharing" begin
        l = PersistentList([1:100])
        l2 = 0..l
        is(l, tail(l2)) => true
    end

    @fact "iteration" begin
        arr2 = Int[]
        for i in PersistentList([1:1000])
            push!(arr2, i)
        end
        1:1000 => arr2
    end

    @fact "map" begin
        map(x->x+1, PersistentList([1,2,3,4,5])) => PersistentList([2,3,4,5,6])
    end

    @fact "reverse" begin
        reverse(PersistentList([1:10])) => 10:-1:1
    end

    @fact "hash" begin
        hash(PersistentList([1:1000])) => hash(PersistentList([1:1000]))
    end

    @fact "isempty" begin
        EmptyList() => isempty
        PersistentList([1])  => not(isempty)
    end

end
