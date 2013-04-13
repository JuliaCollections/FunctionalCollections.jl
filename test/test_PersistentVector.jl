using FactCheck
using PersistentVectors

function PersistentVectors.PersistentVector(r::Range1)
    pv = PersistentVector()
    for i=r pv=append(pv, i) end
    pv
end

function PersistentVectors.TransientVector(r::Range1)
    tv = TransientVector()
    for i=r push!(tv, i) end
    tv
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

    @fact "transient => persistent" begin
        tv = TransientVector()
        push!(tv, 1)
        length(tv) => 1

        pv = persist!(tv)
        typeof(pv) => PersistentVector

        # Cannot mutate transient after call to persist!
        push!(tv, 2) => :throws
    end

end

@facts "Persistent Vectors" begin

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

    @fact "Base.map" begin
        v1 = PersistentVector(1:5)
        map((x)->x+1, v1) => PersistentVector([2, 3, 4, 5, 6])
    end

end
