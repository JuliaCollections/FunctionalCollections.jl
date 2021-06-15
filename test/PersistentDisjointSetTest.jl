using FunctionalCollections
using Test

@testset "Persistent Lists" begin

    @testset "UnionFind" begin
        uf = PersistentDisjointSet{Int}()
        uf = union(uf,2,3)
        uf = union(uf,5,7)
        uf = union(uf,2,4)
        uf = union(uf,4,8)
        @assert uf[1] == 1
        @assert uf[1] != uf[7]
        @assert uf[3] == uf[8]
        @assert uf[5] == uf[7]
        @assert uf[3] != uf[7]
    end

end