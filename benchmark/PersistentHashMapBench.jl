using FunctionalCollections

include("./bench.jl")

println("\nPersistentHashMap")
println("=================\n")

const rands = rand(1:100000, 100000)
const unos = ones(Int, 100000)

pmap = PersistentHashMap{Int, Int}()
dict = Dict{Int, Int}()

for i=1:100000
    pmap = assoc(pmap, i, i)
    dict[i] = i
end

function getting(map, keys)
    function ()
        for k=keys
            map[k]
        end
    end
end

@bench "Getting (big)" 20 [getting(pmap, rands), getting(dict, rands)]
@bench "Getting (small)" 20 [getting(PersistentHashMap((1, 1)), unos)
                             getting([1 => 1], unos)]

function updating(::Type{PersistentHashMap}, keys::Vector{T}) where T
    pmap = PersistentHashMap{T, T}()
    function ()
        for i=keys
            pmap = assoc(pmap, i, i)
        end
    end
end
function updating(::Type{Dict}, keys::Vector{T}) where T
    dict = Dict{T, T}()
    function ()
        for i=keys
            dict[i] = i
        end
    end
end

@bench "Updating" 20 [updating(PersistentHashMap, rand(1:100000, 10000)),
                      updating(Dict, rand(1:100000, 10000))]
