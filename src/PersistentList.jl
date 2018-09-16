abstract type AbstractList{T} end

struct EmptyList{T} <: AbstractList{T} end
EmptyList() = EmptyList{Any}()

struct PersistentList{T} <: AbstractList{T}
    head::T
    tail::AbstractList{T}
    length::Int
end
PersistentList{T}() where {T} = EmptyList{Any}()
function PersistentList{T}(v) where T
    v = reverse(v)
    list = EmptyList{T}()
    for el in v
        list = cons(el, list)
    end
    list
end
PersistentList(itr) = PersistentList{eltype(itr)}(itr)

head(::EmptyList) = throw(BoundsError())
tail(::EmptyList) = throw(BoundsError())
head(l::PersistentList) = l.head
tail(l::PersistentList) = l.tail

first(l::AbstractList) = head(l)

length(::EmptyList) = 0
length(l::PersistentList) = l.length

isempty(::EmptyList) = true
isempty(::PersistentList) = false

cons(val, ::EmptyList{T}) where T = PersistentList{T}(val, EmptyList{T}(), 1)
cons(val, l::PersistentList{T}) where T  = PersistentList{T}(val, l, length(l) + 1)
..(val, l::AbstractList) = cons(val, l)

isequal(::EmptyList, ::EmptyList) = true
isequal(l1::PersistentList, l2::PersistentList) =
    isequal(head(l1), head(l2)) && isequal(tail(l1), tail(l2))
==(::EmptyList, ::EmptyList) = true
==(l1::PersistentList, l2::PersistentList) =
    head(l1) == head(l2) && tail(l1) == tail(l2)


iterate(l::AbstractList) = iterate(l, l)
iterate(::AbstractList, ::EmptyList) = nothing
iterate(::AbstractList, l::PersistentList) = (head(l), tail(l))

isequal(a::AbstractArray, l::PersistentList) = isequal(l, a)
isequal(l::PersistentList, a::AbstractArray) =
    isequal(length(l), length(a)) && all((el) -> el[1] == el[2], zip(l, a))
==(a::AbstractArray, l::PersistentList) = isequal(l, a)
==(l::PersistentList, a::AbstractArray) = isequal(l, a)

map(f::Base.Callable, e::EmptyList) = e
map(f::Base.Callable, l::PersistentList) = cons(f(head(l)), map(f, tail(l)))

filter(f::Function, e::EmptyList) = e
function filter(f::Function, l::PersistentList{T}) where T
    list = EmptyList{T}()
    for el in l
        if f(el)
            list = cons(el, list)
        end
    end
    reverse(list)
end

reverse(e::EmptyList) = e
function reverse(l::PersistentList{T}) where T
    reversed = EmptyList{T}()
    for val in l
        reversed = val..reversed
    end
    reversed
end

 show(io::IO, ::MIME"text/plain", ::EmptyList) = print(io, "()")
 function show(io::IO, ::MIME"text/plain", l::PersistentList{T}) where T
    print(io, "$T($(head(l))")
    for val in tail(l)
        print(io, ", $val")
    end
    print(io, ")")
end
