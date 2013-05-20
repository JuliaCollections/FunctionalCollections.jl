using FunctionalCollections
using FactCheck

@facts "Lists" begin

    @fact "length" begin
        length(List([1])) => 1
        length(List([1, 2, 3])) => 3
        length(EmptyList()) => 0
    end

    @fact "equality" begin
        List([1:100]) => List([1:100])
        List([1:100]) => not(List([1:99]))
        List([1:100]) => [1:100]
    end

    @fact "head" begin
        head(List([1:100])) => 1
        head(List([1]))     => 1
        head(EmptyList())   => :throws
    end

    @fact "tail" begin
        tail(List([1:100])) => List([2:100])
        tail(List([1]))     => EmptyList()
        tail(EmptyList())   => :throws
    end

    @fact "sharing" begin
        l = List([1:100])
        l2 = 0 >> l
        is(l, tail(l2)) => true
    end

    @fact "iteration" begin
        arr2 = Int[]
        for i in List([1:1000])
            push!(arr2, i)
        end
        1:1000 => arr2
    end

    @fact "map" begin
        map(x->x+1, List([1,2,3,4,5])) => List([2,3,4,5,6])
    end

    @fact "reverse" begin
        reverse(List([1:10])) => 10:-1:1
    end

    @fact "hash" begin
        hash(List([1:1000])) => hash(List([1:1000]))
    end

    @fact "isempty" begin
        EmptyList() => isempty
        List([1])  => not(isempty)
    end

end
