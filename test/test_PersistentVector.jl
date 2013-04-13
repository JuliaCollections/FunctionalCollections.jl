using FactCheck
using PersistentVectors

function PersistentVectors.TransientVector(r::Range1)
    tv = TransientVector()
    for i=r push!(tv, i) end
    tv
end

function Base.Array(r::Range1)
    arr = Array(Int, r)
    for i=r arr[i] = i end
    arr
end

@facts "Transient Vectors" begin

    @fact "length" begin
        length(TransientVector(1:32)) => 32
        length(TransientVector(1:10000)) => 10000
    end

    @fact "accessing elements" begin
        tv = TransientVector(1:5000)

        tv[1]    => 1
        tv[32]   => 32
        tv[500]  => 500
        tv[2500] => 2500
        tv[5000] => 5000
        tv[5001] => :throws

        TransientVector(1:32)[33] => :throws
    end

    @fact "updating" begin
        tv = TransientVector(1:5000)

        (tv[1000] = "foo") => "foo"
        tv[1000] => "foo"
    end

    @fact "transient => persistent" begin
        tv = TransientVector()
        push!(tv, 1)
        length(tv) => 1

        pv = persist!(tv)
        typeof(pv) => PersistentVector

        # Cannot mutate transient after call to persist!
        push!(tv, 2) => :throws

        tv = TransientVector(1:1000)
        pv = persist!(tv)
        typeof(pv.self[1]) => PersistentVector
        tv.self[1].persistent => true
    end

end

PersistentVectors.PersistentVector(r::Range1) = persist!(TransientVector(r))

@facts "Persistent Vectors" begin

    @fact "range constructor" begin
        typeof(PersistentVector(1:1000)) => PersistentVector
        typeof(pop(PersistentVector(1:1000))) => PersistentVector
    end

    @fact "length" begin
        length(PersistentVector(1:32)) => 32
        length(PersistentVector(1:10000)) => 10000
        length(pop(PersistentVector(1:1000))) => 999
    end

    @fact "accessing elements" begin
        pv = PersistentVector(1:5000)

        pv[1]    => 1
        pv[32]   => 32
        pv[500]  => 500
        pv[2500] => 2500
        pv[5000] => 5000
        pv[5001] => :throws

        PersistentVector(1:32)[33] => :throws
    end

    @fact "accessing last" begin
        peek(PersistentVector(1:1000)) => 1000
        PersistentVector(1:1000)[end]  => 1000
    end

    @fact "updating" begin
        update(PersistentVector(1:1000), 500, "foo")[500] => "foo"
    end

    @fact "structural sharing" begin
        pv = PersistentVector(1:32)
        pv2 = append(pv, 33)
        is(pv2.self[1], pv) => true
    end

    @fact "Base.==" begin
        v1 = PersistentVector(1:1000)
        v2 = PersistentVector(1:1000)

        is(v1.self, v2.self) => false
        v1 => v2
    end

    @fact "iteration" begin
        arr2 = Int[]
        for i in PersistentVector(1:10000)
            push!(arr2, i)
        end
        1:10000 => arr2
    end

    @fact "Base.map" begin
        v1 = PersistentVector(1:5)
        map((x)->x+1, v1) => PersistentVector([2, 3, 4, 5, 6])
    end

end
