using Compat
using FactCheck
using FunctionalCollections

facts("@Persistent constructor macro") do

    context("Persistent Vectors") do
        @fact @Persistent([1, 2, 3]) --> pvec([1, 2, 3])
    end

    context("Persistent Hash Maps") do
        @fact @Persistent(["foo" => 1, "bar" => 2]) --> phmap(("foo", 1), ("bar", 2))
        @fact @Persistent(Dict("foo" => 1, "bar" => 2)) --> phmap(("foo", 1), ("bar", 2))
    end

    context("Persistent Set") do
        @fact @Persistent(Set(1, 2, 3, 3)) --> pset(1, 2, 3, 3)
    end

end
