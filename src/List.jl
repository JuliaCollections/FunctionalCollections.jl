abstract AbstractList{T}

immutable EmptyList{T} <: AbstractList{T} end
EmptyList() = EmptyList{Any}()

immutable List{T} <: AbstractList{T}
    head::T
    tail::AbstractList{T}
    length::Int
end

head(::EmptyList) = error(BoundsError())
tail(::EmptyList) = error(BoundsError())
head(l::List) = l.head
tail(l::List) = l.tail

Base.first(l::AbstractList) = head(l)

Base.length(::EmptyList) = 0
Base.length(l::List) = l.length

Base.isempty(::EmptyList) = true
Base.isempty(::List)      = false

import Base.>>
cons{T}(val::T, ::EmptyList) = List(val, EmptyList{T}(), 1)
cons{T}(val::T, l::List{T})  = List(val, l, length(l) + 1)
>>(val, l::AbstractList) = cons(val, l)

Base.isequal(::EmptyList, ::EmptyList) = true
Base.isequal(l1::List, l2::List) =
    isequal(head(l1), head(l2)) && isequal(tail(l1), tail(l2))

function List{T}(v::Vector{T})
    v = reverse(v)
    list = EmptyList{T}()
    for el in v
        list = cons(el, list)
    end
    list
end

Base.start(l::AbstractList) = l
Base.done(::AbstractList, ::EmptyList) = true
Base.done(::AbstractList, ::List)      = false
Base.next(::AbstractList, l::List) = (head(l), tail(l))

Base.isequal(a::AbstractArray, l::List) = isequal(l, a)
Base.isequal(l::List, a::AbstractArray) =
    isequal(length(l), length(a)) && all((el) -> el[1] == el[2], zip(l, a))

Base.map(f, e::EmptyList) = e
Base.map(f, l::List) = cons(f(head(l)), map(f, tail(l)))

Base.reverse(e::EmptyList) = e
function Base.reverse{T}(l::List{T})
    reversed = EmptyList{T}()
    for val in l
        reversed = val >> reversed
    end
    reversed
end

Base.show(io::IO, ::EmptyList) = print(io, "()")
function Base.show{T}(io::IO, l::List{T})
    print(io, "$T($(head(l))")
    for val in tail(l)
        print(io, ", $val")
    end
    print(io, ")")
end
