type NotFound end

immutable KVPair{K, V}
    key::K
    value::V
end

Base.isequal(kv1::KVPair, kv2::KVPair) =
    kv1.key == kv2.key && kv1.value == kv2.value

Base.hash(kv::KVPair) = uint(Base.bitmix(hash(kv.key), hash(kv.value)))

totuple(kv::KVPair) = (kv.key, kv.value)

Base.show(io::IO, kv::KVPair) = print(io, "$(kv.key) => $(kv.value)")
