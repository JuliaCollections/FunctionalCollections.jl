# Persistent Vector: based on the Bitmapped Vector Trie
#
module PVectors

export Zero,
       One,
       Two,
       Three,
       Four,
       Five,
       Six,
       Trie,
       apply,
       update,
       append,
       pop

import Base: getindex, setindex!, length, copy, endof

outofbounds(i) = error("Index out of bounds: $i")

function copy(arr1::Array, arr2::Array, n::Int)
    for i in 1:n
        arr2[i] = arr1[i]
    end
    arr2
end
function copy(arr::Array, n::Int)
    arr2 = Array(Any, n)
    copy(arr, arr2, min(length(arr), length(arr2)))
end
copy(arr1::Array, arr2::Array) = copy(arr1, arr2, length(arr1))

# Vector Tries
# ============

const ZeroThresh  = 0
const OneThresh   = 32
const TwoThresh   = 32 << 5
const ThreeThresh = 32 << 10
const FourThresh  = 32 << 15
const FiveThresh  = 32 << 20
const SixThresh   = 32 << 25

abstract TrieCase

macro triecase(case::Symbol, shift::Int)
    abstract_case = symbol(string("T", case))
    case = esc(case)
    shiftfn = esc(:shift)
    quote
        type $abstract_case <: TrieCase end
        $case = $abstract_case()
        $shiftfn(::$abstract_case) = $shift
    end
end

@triecase Zero -1
@triecase One 0
@triecase Two 5
@triecase Three 10
@triecase Four 15
@triecase Five 20
@triecase Six 25

immutable Trie
    case::TrieCase
    arr::Array
end

getindex(t::Trie, i::Int) = t.arr[i]
setindex!(t::Trie, o, i::Int) = setindex!(t.arr, o, i)
endof(t::Trie) = endof(t.arr)
length(t::Trie) = length(t.arr)
copy(t::Trie) = Trie(t.case, t.arr[1:end])
copy(t::Trie, n::Int) = Trie(t.case, copy(t.arr, n))

# Operations
# ==========

# apply
#
apply(::TZero, t::Trie, i::Int) = outofbounds(i)

apply(::TOne, t::Trie, i::Int) = t

macro defapply(case)
    applyfn = esc(:apply)
    quote
        typ = typeof($case)
        function $applyfn(::typ, t::Trie, i::Int)
            a = t[(i >>> shift($case)) & 31]
            apply(a, i)
        end
    end
end

@defapply Two
@defapply Three
@defapply Four
@defapply Five
@defapply Six

# update
#
update(::TZero, t::Trie, i::Int, o) = outofbounds(i)

function update(::TOne, t::Trie, i::Int, o)
    t2 = copy(t)
    t2[i & 31] = o
    t2
end

macro defupdate(case)
    updatefn = esc(:update)
    quote
        typ = typeof($case)
        function $updatefn(::typ, t::Trie, i::Int, o)
            t2 = copy(t)
            t2[(i >>> shift($case)) & 31] =
                update(t2[(i >>> shift($case)) & 31], i, o)
            t2
        end
    end
end

@defupdate Two
@defupdate Three
@defupdate Four
@defupdate Five
@defupdate Six

# append
#
append(::TZero, t::Trie, node::Array) = Trie(One, node)

append(::TOne, t::Trie, tail::Array) = Trie(Two, Any[t.arr, tail])

function append(::TTwo, t::Trie, tail::Array)
    if length(t) >= 32
        Trie(Three, Any[t.arr, Any[tail]])
    else
        t2 = copy(t, length(t) + 1)
        t2[end] = tail
        t2
    end
end

function append(::TThree, t::Trie, tail::Array)
    if length(t[end]) >= 32
        if length(t) >= 32
            Trie(Four, Any[t.arr, Any[Any[tail]]])
        else
            t2 = copy(t, length(t) + 1)
            t2[end] = Any[tail]
            t2
        end
    else
        t2 = copy(t)
        t2[end] = copy(t2[end], length(t2[end]) + 1)
        t2[end][end] = tail
        t2
    end
end

function append(::TFour, t::Trie, tail::Array)
    if length(t[end][end]) >= 32
        if length(t[end]) >= 32
            if length(t) >= 32
                Trie(Five, Any[t.arr, Any[Any[Any[tail]]]])
            else
                t2 = copy(t, length(t) + 1)
                t2[end] = Any[Any[tail]]
                t2
            end
        else
            t2 = copy(t)
            t2[end] = copy(t2[end], length(t2[end]) + 1)
            t2[end][end] = Any[tail]
            t2
        end
    else
        t2 = copy(t)
        t2[end] = copy(t2[end])
        t2[end][end] = copy(t2[end][end], length(t2[end][end]) + 1)
        t2[end][end][end] = tail
        t2
    end
end

function append(::TFive, t::Trie, tail::Array)
    if length(t[end][end][end]) >= 32
        if length(t[end][end]) >= 32
            if length(t[end]) >= 32
                if length(t) >= 32
                    Trie(Six, Any[t.arr, Any[Any[Any[Any[tail]]]]])
                else
                    t2 = copy(t, length(t) + 1)
                    t2[end] = Any[Any[Any[tail]]]
                    t2
                end
            else
                t2 = copy(t)
                t2[end] = copy(t2[end], length(t2[end]) + 1)
                t2[end][end] = Any[Any[tail]]
                t2
            end
        else
            t2 = copy(t)
            t2[end] = copy(t2[end])
            t2[end][end] = copy(t2[end][end], length(t2[end][end]) + 1)
            t2[end][end][end] = Any[tail]
            t2
        end
    else
        t2 = copy(t)
        t2[end] = copy(t2[end])
        t2[end][end] = copy(t2[end][end])
        t2[end][end][end] = copy(t2[end][end][end], length(t2[end][end][end]) + 1)
        t2[end][end][end][end] = tail
        t2
    end
end

function append(::TSix, t::Trie, tail::Array)
    if length(t[end][end][end][end]) >= 32
        if length(t[end][end][end]) >= 32
            if length(t[end][end]) >= 32
                if length(t[end]) >= 32
                    if length(t) >= 32
                        error("PVector at max size")
                    else
                        t2 = copy(t, length(t) + 1)
                        t2[end] = Any[Any[Any[Any[tail]]]]
                        t2
                    end
                else
                    t2 = copy(t)
                    t2[end] = copy(t2[end], length(t2[end]) + 1)
                    t2[end][end] = Any[Any[Any[tail]]]
                    t2
                end
            else
                t2 = copy(t)
                t2[end] = copy(t2[end])
                t2[end][end] = copy(t2[end][end], length(t2[end][end]) + 1)
                t2[end][end][end] = Any[Any[tail]]
                t2
            end
        else
            t2 = copy(t)
            t2[end] = copy(t2[end])
            t2[end][end] = copy(t2[end][end])
            t2[end][end][end] = copy(t2[end][end][end], length(t2[end][end][end]) + 1)
            t2[end][end][end][end] = Any[tail]
            t2
        end
    else
        t2 = copy(t)
        t2[end] = copy(t2[end])
        t2[end][end] = copy(t2[end][end])
        t2[end][end][end] = copy(t2[end][end][end], length(t2[end][end][end]))
        t2[end][end][end][end] = copy(t2[end][end][end][end], length(t2[end][end][end][end]) + 1)
        t2[end][end][end][end][end] = tail
        t2
    end
end

# pop
#
pop(::TZero, t::Trie) = outofbounds(i)

pop(::TOne, t::Trie) = (Zero, t)

function pop(::TTwo, t::Trie)
    if length(trie) == 2
        (t[1], t[end])
    else
        t2 = copy(t, length(t) - 1)
        (t2, t[end])
    end
end


# TrieCase dispatch
shift(t::Trie) = shift(t.case)
apply(t::Trie, i::Int) = apply(t.case, t, i)
update(t::Trie, i::Int, o) = update(t.case, t, i, o)
append(t::Trie, tail::Array) = append(t.case, t, tail)
pop(t::Trie) = pop(t.case, t)

# PVector
# =======

immutable PVector
    len::Int
    trie::Trie
    tail::Array{Any, 1}
    tailoff::Int

    PVector(len::Int, trie::Trie, tail::Array{Any, 1}) =
        new(len, trie, tail, length - length(tail))
end

bounds_check(pv::PVector, i::Int) =
    i >= 1 && i <= pv.len || error("Index out of bounds: $i")

function apply(pv::PVector, i::Int)
    bounds_check(pv, i)
    if i >= tailoff
        pv.tail[i & 31]
    else
        pv.trie[i][i & 31]
    end
end

function update(pv::PVector, i::Int, obj)
    bounds_check(pv, i)
    if i >= tailoff
        newtail = pv.tail[1:end]
        newtail[i & 31] = obj
        PVector(pv.len, pv.trie, newtail)
    else
        pv.trie[i] = obj
        PVector(pv.len, pv.trie, pv.tail)
    end
end

function append(pv::PVector, obj)
    if length(pv.tail) < 32
        tail2 = Array(Any, length(pv.tail) + 1)
        copy(pv.tail, tail2)
        tail2[end] = obj

        PVector(pv.len + 1, pv.trie, tail2)
    else
        PVector(pv.len + 1, append(pv.trie, pv.tail), Any[obj])
    end
end

function pop(pv::PVector)
    pv.len == 0 && error("Can't pop empty PVector")
    if pv.len == 1
        PVector()
    elseif length(pv.tail) > 1
        tail2 = Array(Any, length(pv.tail) - 1)
        copy(pv.tail, tail2, length(tail2))

        PVector(pv.len - 1, pv.trie, tail2)
    else
        trie2, tail2 = pop(pv.trie)
        PVector(pv.len - 1, trie2, tail2)
    end
end

end # module PVector
