using FactCheck
using PersistentVectors

function PersistentVectors.PersistentVector(r::Range1)
    pv = PersistentVector()
    for i=r pv=append(pv, i) end
    pv
end

@facts "Persistent Vectors" begin

    @fact length(PersistentVector(1:32)) => 32
    @fact length(PersistentVector(1:10000)) => 10000
    @fact length(pop(PersistentVector(1:1000))) => 999

    pv = PersistentVector(1:5000)

    @fact "about accessing elements" begin
        pv[1]    => 1
        pv[32]   => 32
        pv[500]  => 500
        pv[2500] => 2500
        pv[5000] => 5000
        pv[5001] => :throws
    end

    @fact peek(PersistentVector(1:1000)) => 1000
    @fact PersistentVector(1:1000)[end]  => 1000

    @fact update(PersistentVector(1:1000), 500, "foo")[500] => "foo"

    pv = PersistentVector(1:32)
    pv2 = append(pv, 33)
    @fact pv2.self[1] => pv

end
