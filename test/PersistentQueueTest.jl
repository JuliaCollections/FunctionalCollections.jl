using FunctionalCollections
using FactCheck

facts("Persistent Queues") do

    context("equality") do
        @fact PersistentQueue(1:100) --> PersistentQueue(1:100)
        @fact PersistentQueue(1:100) --> not(PersistentQueue(1:99))
    end

    context("isempty") do
        @fact PersistentQueue{Int}() --> isempty
        @fact PersistentQueue([1])   --> not(isempty)
    end

    context("peek") do
        @fact peek(PersistentQueue(1:100)) --> 100
        @fact try peek(PersistentQueue{Int}()); false catch e true end --> true
    end

    context("pop") do
        @fact pop(PersistentQueue(1:100)) --> PersistentQueue(1:99)
        @fact try pop(PersistentQueue{Int}()); false catch e true end --> true
    end

    context("enq") do
        q = PersistentQueue{Int}()
        @fact peek(enq(q, 1)) --> 1
        @fact peek(pop(pop(enq(enq(enq(q, 1), 2), 3)))) --> 3
    end

    context("iteration") do
        arr2 = Int[]
        for i in PersistentQueue(1:1000)
            push!(arr2, i)
        end
        @fact arr2 --> collect(1000:-1:1)
    end

    context("hash") do
        @fact hash(PersistentQueue(1:1000)) --> hash(PersistentQueue(1:1000))
    end

    context("length") do
        @fact length(PersistentQueue([1, 2, 3])) --> 3
        @fact length(PersistentQueue{Int}()) --> 0

        @fact length(pop(PersistentQueue([1, 2, 3]))) --> 2
    end

end
