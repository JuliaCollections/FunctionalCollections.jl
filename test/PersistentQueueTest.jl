using FunctionalCollections
using FactCheck

@facts "Persistent Queues" begin

    @fact "equality" begin
        PersistentQueue([1:100]) => PersistentQueue([1:100])
        PersistentQueue([1:100]) => not(PersistentQueue([1:99]))
    end

    @fact "isempty" begin
        PersistentQueue{Int}() => isempty
        PersistentQueue([1])   => not(isempty)
    end

    @fact "peek" begin
        peek(PersistentQueue([1:100])) => 100
        peek(PersistentQueue{Int}()) => :throws
    end

    @fact "pop" begin
        pop(PersistentQueue([1:100])) => PersistentQueue([1:99])
        pop(PersistentQueue{Int}()) => :throws
    end

    @fact "enq" begin
        q = PersistentQueue{Int}()
        peek(enq(q, 1)) => 1
        peek(pop(pop(enq(enq(enq(q, 1), 2), 3)))) => 3
    end

    @fact "iteration" begin
        arr2 = Int[]
        for i in PersistentQueue([1:1000])
            push!(arr2, i)
        end
        arr2 = 1000:-1:1
    end

    @fact "hash" begin
        hash(PersistentQueue([1:1000])) => hash(PersistentQueue([1:1000]))
    end

    @fact "length" begin
        length(PersistentQueue([1, 2, 3])) => 3
        length(PersistentQueue{Int}()) => 0

        length(pop(PersistentQueue([1, 2, 3]))) => 2
    end

end
