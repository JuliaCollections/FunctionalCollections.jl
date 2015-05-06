using FunctionalCollections
using FactCheck

facts("Persistent Lists") do

    context("length") do
        @fact length(PersistentList([1])) => 1
        @fact length(PersistentList([1, 2, 3])) => 3
        @fact length(EmptyList()) => 0
    end

    context("equality") do
        @fact PersistentList(1:100) => PersistentList(1:100)
        @fact PersistentList(1:100) => not(PersistentList(1:99))
        @fact PersistentList(1:100) => collect(1:100)
    end

    context("head") do
        @fact head(PersistentList(1:100)) => 1
        @fact head(PersistentList([1]))   => 1
        @fact try head(EmptyList()); false catch e true end => true
    end

    context("tail") do
        @fact tail(PersistentList(1:100)) => PersistentList(2:100)
        @fact tail(PersistentList([1]))     => EmptyList()
        @fact try tail(EmptyList()); false catch e true end => true
    end

    context("cons") do
        @fact cons(1, cons(2, cons(3, EmptyList()))) => PersistentList([1, 2, 3])
        @fact 1..(2..(3..EmptyList())) => PersistentList([1, 2, 3])
    end

    context("sharing") do
        l = PersistentList(1:100)
        l2 = 0..l
        @fact is(l, tail(l2)) => true
    end

    context("iteration") do
        arr2 = Int[]
        for i in PersistentList(1:1000)
            push!(arr2, i)
        end
        @fact collect(1:1000) => arr2
    end

    context("map") do
        @fact map(x->x+1, PersistentList([1,2,3,4,5])) => PersistentList([2,3,4,5,6])
    end

    context("reverse") do
        @fact reverse(PersistentList(1:10)) => 10:-1:1
    end

    context("hash") do
        @fact hash(PersistentList(1:1000)) => hash(PersistentList(1:1000))
    end

    context("isempty") do
        @fact EmptyList() => isempty
        @fact PersistentList([1])  => not(isempty)
    end

end
