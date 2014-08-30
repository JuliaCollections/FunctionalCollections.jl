abstract AbstractList{T}

immutable EmptyList{T} <: AbstractList{T} end
EmptyList() = EmptyList{Any}()

immutable PersistentList{T} <: AbstractList{T}
    head::T
    tail::AbstractList{T}
    length::Int
    PersistentList(head::T, tail::AbstractList{T}, length) =
        new(head, tail, length)
    PersistentList() = EmptyList{Any}()
    function PersistentList(v)
        v = reverse(v)
        list = EmptyList{T}()
        for el in v
            list = cons(el, list)
        end
        list
    end
end
PersistentList(itr) = PersistentList{eltype(itr)}(itr)

head(::EmptyList) = error(BoundsError())
tail(::EmptyList) = error(BoundsError())
head(l::PersistentList) = l.head
tail(l::PersistentList) = l.tail

Base.first(l::AbstractList) = head(l)

Base.length(::EmptyList) = 0
Base.length(l::PersistentList) = l.length

Base.isempty(::EmptyList) = true
Base.isempty(::PersistentList)      = false

cons{T}(val, ::EmptyList{T}) = PersistentList{T}(val, EmptyList{T}(), 1)
cons{T}(val, l::PersistentList{T})  = PersistentList{T}(val, l, length(l) + 1)
..(val, l::AbstractList) = cons(val, l)

Base.isequal(::EmptyList, ::EmptyList) = true
Base.isequal(l1::PersistentList, l2::PersistentList) =
    isequal(head(l1), head(l2)) && isequal(tail(l1), tail(l2))


Base.start(l::AbstractList) = l
Base.done(::AbstractList, ::EmptyList) = true
Base.done(::AbstractList, ::PersistentList)      = false
Base.next(::AbstractList, l::PersistentList) = (head(l), tail(l))

Base.isequal(a::AbstractArray, l::PersistentList) = isequal(l, a)
Base.isequal(l::PersistentList, a::AbstractArray) =
    isequal(length(l), length(a)) && all((el) -> el[1] == el[2], zip(l, a))

Base.map(f::Union(Function, DataType), e::EmptyList) = e
Base.map(f::Union(Function, DataType), l::PersistentList) = cons(f(head(l)), map(f, tail(l)))

Base.reverse(e::EmptyList) = e
function Base.reverse{T}(l::PersistentList{T})
    reversed = EmptyList{T}()
    for val in l
        reversed = val..reversed
    end
    reversed
end

Base.show(io::IO, ::EmptyList) = print(io, "()")
function Base.show{T}(io::IO, l::PersistentList{T})
    print(io, "$T($(head(l))")
    for val in tail(l)
        print(io, ", $val")
    end
    print(io, ")")
end
