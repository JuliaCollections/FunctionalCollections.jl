struct PersistentQueue{T}
    in::AbstractList{T}
    out::AbstractList{T}
    length::Int
end

PersistentQueue{T}() where {T} =
    PersistentQueue{T}(EmptyList{T}(), EmptyList{T}(), 0)
PersistentQueue(v::AbstractVector{T}) where {T} =
    PersistentQueue{T}(EmptyList{T}(), reverse(PersistentList(v)), length(v))

queue = PersistentQueue

Base.length(q::PersistentQueue) = q.length
Base.isempty(q::PersistentQueue) = (q.length === 0)

peek(q::PersistentQueue) = isempty(q.out) ? head(reverse(q.in)) : head(q.out)

pop(q::PersistentQueue{T}) where {T} =
    if isempty(q.out)
        PersistentQueue{T}(EmptyList{T}(), tail(reverse(q.in)), length(q) - 1)
    else
        PersistentQueue{T}(q.in, tail(q.out), length(q) - 1)
    end

enq(q::PersistentQueue{T}, val) where {T} =
    if isempty(q.in) && isempty(q.out)
        PersistentQueue{T}(q.in, val..EmptyList{T}(), 1)
    else
        PersistentQueue{T}(val..q.in, q.out, length(q) + 1)
    end


Base.iterate(q::PersistentQueue) = iterate(q, (q.in, q.out))
Base.iterate(::PersistentQueue{T}, ::Tuple{EmptyList{T}, EmptyList{T}}) where {T} = nothing
Base.iterate(::PersistentQueue{T}, (in, out)::Tuple{AbstractList{T}, PersistentList{T}}) where {T} =
    head(out), (in, tail(out))
Base.iterate(q::PersistentQueue{T}, (in, out)::Tuple{PersistentList{T}, EmptyList{T}}) where {T} =
    iterate(q, (EmptyList{T}(), reverse(in)))
