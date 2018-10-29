using FunctionalCollections
using Test

const PAM = PersistentArrayMap

@testset "Persistent Array Maps" begin

    @testset "construction" begin
        @test length(PAM{Int, Int}().kvs) == 0
        @test length(PAM((1, 1), (2, 2)).kvs) == 2

        @test length(PAM((1, 1))) == 1
        @test length(PAM((1, 1), (2, 2))) == 2
    end

    @testset "accessing" begin
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        @test m[1] == "one"
        @test m[2] == "two"
        @test m[3] == "three"

        @test get(m, 1) == "one"
        @test get(m, 1, "foo") == "one"
        @test get(m, 4, "foo") == "foo"
    end

    @testset "haskey" begin
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        @test haskey(m, 1)
        @test haskey(m, 2)
        @test haskey(m, 3)
        @test !haskey(m, 4)
    end

    @testset "assoc" begin
        m = PAM{Int, String}()
        @test assoc(m, 1, "one")[1] == "one"
        @test try m[1]; false catch e true end

        m = PAM((1, "one"))
        @test assoc(m, 1, "foo")[1] == "foo"
    end

    @testset "dissoc" begin
        m = PAM((1, "one"))
        m = dissoc(m, 1)
        @test try m[1]; false catch e true end

        m = PAM((1, "one"), (2, "two"))
        @test dissoc(m, 1) == PAM((2, "two"))
    end

    @testset "iterating" begin
        m = PAM((1, "one"), (2, "two"), (3, "three"))
        @test [v for (k, v) in m] == ["one", "two", "three"]
    end

    @testset "isempty" begin
        @test isempty(PAM{Int, Int}())
        @test !isempty(PAM((1, "one")))
    end

    @testset "equality" begin
        @test PAM((1, "one")) == PAM((1, "one"))
        @test PAM((1, "one"), (2, "two")) == PAM((2, "two"), (1, "one"))
        @test isequal(PAM((1, "one")), PAM((1, "one")))

        @test PAM((1, "one")) != (PAM((2, "two")))
    end

    @testset "kwargs construction" begin
        @test PAM(x=1, y=2, z=3) == PAM((:x, 1), (:y, 2), (:z, 3))
    end

    @testset "map" begin
        m = PAM((1, 1), (2, 2), (3, 3))

        @test map((kv) -> (kv[1], kv[2]+1), m) == PAM((1, 2), (2, 3), (3, 4))
    end
end

const PHM = PersistentHashMap

@testset "Persistent Hash Maps" begin

    @testset "constructor" begin
        hashmap = PHM{Int, Int}()
        @test length(hashmap) == 0
        @test length(PHM((1, 1), (2, 2), (3, 3))) == 3
        @test length(PHM(x=1, y=2, z=3)) == 3
    end

    @testset "equality" begin
        @test PHM{Int, Int}() == PHM{Int, Int}()
        @test PHM{Int, Int}() == PHM{String, String}()

        m1 = PHM{Int, Int}()
        m2 = PHM{Int, Int}()
        @test assoc(m1, 1, 100) == assoc(m2, 1, 100)
        @test assoc(m1, 1, 100) != (assoc(m2, 1, 200))
        @test assoc(m1, 1, 100) != (assoc(m2, 2, 100))

        m3 = PHM([(1 => 10), (2 => 20), (3 => 30)])
        m4 = PHM((3, 30), (2, 20), (1, 10))
        @test m3 == m4
        @test m3 != (m1)

        @test m3 == Dict(1 => 10, 2 => 20, 3 => 30)
    end

    @testset "assoc" begin
        m = PHM{Int, String}()
        @test assoc(m, 1, "one")[1] == "one"
        @test try m[1]; false catch e true end

        m = PHM{Int, String}()
        m = assoc(m, 1, "one")
        @test assoc(m, 1, "foo")[1] == "foo"
    end

    @testset "covariance" begin
        m = PHM{Any, Any}()
        @test assoc(m, "foo", "bar") == (Dict("foo" => "bar"))
    end

    @testset "dissoc" begin
        m = PAM((1, "one"))
        m = dissoc(m, 1)
        @test try m[1]; false catch e true end

        m = PHM((1, "one"), (2, "two"))
        @test dissoc(m, 1) == PHM((2, "two"))
    end

    @testset "get" begin
        m = PHM{Int, String}()
        @test get(m, 1, "default") == "default"
        m = assoc(m, 1, "one")
        @test get(m, 1, "default") == "one"
        m = assoc(m, 1, "newone")
        @test get(m, 1, "default") == "newone"
        @test try get(m, 2); false catch e true end
    end

    @testset "haskey" begin
        m = PHM{Int, String}()
        @test !haskey(m, 1)
        m = assoc(m, 1, "one")
        @test haskey(m, 1)
        @test !haskey(m, 2)
    end

    @testset "haskey dissoc" begin
        m = PHM{Int, String}()
        m = assoc(m, 1, "one")
        m = dissoc(m, 1)
        @test !haskey(m, 1)
    end

    @testset "map" begin
        m = PHM((1, 1), (2, 2), (3, 3))
        @test map((kv) -> (kv[1], kv[2]+1), m) == PHM((1, 2), (2, 3), (3, 4))
    end

    @testset "filter" begin
        @test filter((kv) -> iseven(kv[2]), PHM((1, 1), (2, 2))) == PHM((2, 2))
    end

    @testset "merge" begin
        @test merge(PHM((1, 1), (2, 2)), PHM((2, 3), (3, 4))) ==
                PHM((1,1), (2, 3), (3, 4))
    end
end
