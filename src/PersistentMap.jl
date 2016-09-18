abstract PersistentMap{K, V} <: Associative{K, V}

type NotFound end

immutable KVPair{K, V}
    key::K
    value::V
end

Base.convert(::Type{Tuple}, kv::KVPair) = (kv.key, kv.value)
Base.convert{K, V}(::Type{KVPair{K, V}}, kv::KVPair) =
    KVPair{K, V}(convert(K, kv.key), convert(V, kv.value))

Base.isequal(kv1::KVPair, kv2::KVPair) =
    isequal(kv1.key, kv2.key) && isequal(kv1.value, kv2.value)
Base.isequal(kv::KVPair, tup::Tuple) = isequal(convert(Tuple, kv), tup)
Base.isequal(tup::Tuple, kv::KVPair) = isequal(kv, tup)
==(kv1::KVPair, kv2::KVPair) = kv1.key == kv2.key && kv1.value == kv2.value
==(kv::KVPair, tup::Tuple) = convert(Tuple, kv) == tup
==(tup::Tuple, kv::KVPair) = kv == tup

Base.hash(kv::KVPair) = @compat UInt(Base.hash(kv.key, hash(kv.value)))

@compat Base.show(io::IO, ::MIME"text/plain", kv::KVPair) = print(io, "$(kv.key) => $(kv.value)")
