using FunctionalCollections

include("./bench.jl")

println("\nPersistentVector")
println("================\n")

const rands = rand(1:1000000, 100000)

function appending(::Type{PersistentVector})
    function ()
        v = PersistentVector{Int}()
        for i=1:250000
            v = append(v, i)
        end
    end
end
function appending(::Type{Array})
    function ()
        a = Int[]
        for i=1:250000
            a = push!(a, i)
        end
    end
end

@bench "Appending" 20 [appending(PersistentVector),
                       appending(Array)]

vec(r::Range1) = PersistentVector([r])

function iterating(::Type{PersistentVector})
    pv = vec(1:500000)
    function ()
        sum = 0
        for el in pv
            sum += el
        end
    end
end
function iterating(::Type{Array})
    arr = [1:500000]
    function ()
        sum = 0
        for el in arr
            sum += el
        end
    end
end

@bench "Iterating" 20 [iterating(PersistentVector),
                       iterating(Array)]

function indexing(v::PersistentVector{T}) where T
    function ()
        for idx in rands
            v[idx]
        end
    end
end
function indexing(a::Array{T}) where T
    function ()
        for idx in rands
            a[idx]
        end
    end
end

@bench "Indexing" 20 [indexing(vec(1:1000000)), indexing(Array(Int, 1000000))]

function popping(::Type{PersistentVector})
    v = vec(1:100000)
    function ()
        v2 = v
        for _ in 1:length(v2)
            v2 = pop(v2)
        end
    end
end
function popping(::Type{Array})
    function ()
        a = Array(Int, 100000)
        for _ in 1:length(a)
            pop!(a)
        end
    end
end

@bench "Popping" 20 [popping(PersistentVector), popping(Array)]

function updating(v::PersistentVector{Int})
    function ()
        for idx in rands
            assoc(v, idx, 1)
        end
    end
end
function updating(a::Array{Int})
    function ()
        for idx in rands
            a[idx] = 1
        end
    end
end

@bench "Updating" 20 [updating(vec(1:1000000)), updating(Array(Int, 1000000))]
