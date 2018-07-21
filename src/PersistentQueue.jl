struct PersistentQueue{T}
    in::AbstractList{T}
    out::AbstractList{T}
    length::Int
end

(::Type{PersistentQueue{T}}){T}() =
    PersistentQueue{T}(EmptyList{T}(), EmptyList{T}(), 0)
PersistentQueue{T}(v::AbstractVector{T}) =
    PersistentQueue{T}(EmptyList{T}(), reverse(PersistentList(v)), length(v))

queue = PersistentQueue

Base.length(q::PersistentQueue) = q.length
Base.isempty(q::PersistentQueue) = (q.length === 0)

peek(q::PersistentQueue) = isempty(q.out) ? head(reverse(q.in)) : head(q.out)

pop{T}(q::PersistentQueue{T}) =
    if isempty(q.out)
        PersistentQueue{T}(EmptyList{T}(), tail(reverse(q.in)), length(q) - 1)
    else
        PersistentQueue{T}(q.in, tail(q.out), length(q) - 1)
    end

enq{T}(q::PersistentQueue{T}, val) =
    if isempty(q.in) && isempty(q.out)
        PersistentQueue{T}(q.in, val..EmptyList{T}(), 1)
    else
        PersistentQueue{T}(val..q.in, q.out, length(q) + 1)
    end

Base.start(q::PersistentQueue) = (q.in, q.out)
Base.done{T}(::PersistentQueue{T}, state::(Tuple{EmptyList{T}, EmptyList{T}})) = true
Base.done(::PersistentQueue, state) = false

function Base.next{T}(::PersistentQueue{T}, state::(Tuple{AbstractList{T},
                                                                  PersistentList{T}}))
    in, out = state
    (head(out), (in, tail(out)))
end
function Base.next{T}(q::PersistentQueue{T}, state::(Tuple{PersistentList{T},
                                                                   EmptyList{T}}))
    in, out = state
    next(q, (EmptyList{T}(), reverse(in)))
end
