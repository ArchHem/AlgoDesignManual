#similar logic used in the Datastructures.jl packae...
abstract type AbstractList{T} end
abstract type LinkedList{T} <: AbstractList{T} end
abstract type StaticLinkedList{T} <: LinkedList{T} end
abstract type MLinkedList{T} <: LinkedList{T} end

Base.eltype(x::AbstractList{T}) where T = T

#----------------------------
#Immutable, simply linked list

struct StaticListNode{T} <: StaticLinkedList{T}
    value::T
    next::StaticLinkedList{T}
end

struct StaticListEnd{T} <: StaticLinkedList{T}

end

function StaticListEnd(x::T) where T
    return StaticListEnd{T}()
end

function StaticListNode(x::T) where T
    return StaticListNode{T}(x, StaticListEnd{T}())
end

function StaticListNode(x::T, y::StaticLinkedList{T}) where T
    return StaticListNode{T}(x, y)
end

function StaticListNode(x...)
    T = promote_type(typeof.(x)...)
    node = StaticListNode(convert(T,x[end]))
    #since its a tuple, its safe to rely on the default implementation.
    for i in (length(x)-1):-1:1
        node = StaticListNode{T}(convert(T,x[i]), node)
    end
    return node
end

function Base.reverse(x::StaticListNode{T}) where T
    currbegin = StaticListEnd{T}()
    for elem in x
        currbegin = StaticListNode(elem, currbegin)
    end
    return currbegin
end

function Base.reverse(x::StaticListEnd{T}) where T
    return x
end

Base.length(x::StaticListNode) = begin
    n = 0
    for elem in x
        n +=1 
    end
    return n
end

Base.length(x::StaticListEnd) = begin
    return 0
end

Base.copy(x::StaticListEnd) = x
Base.copy(x::StaticListNode) = reverse(reverse(x))

#iteration base case
Base.iterate(l::StaticLinkedList, ::StaticListEnd) = nothing
function Base.iterate(l::StaticLinkedList, state::StaticListNode = l)
    state.value, state.next
end

Base.lastindex(x::StaticLinkedList) = length(x)
Base.firstindex(x::StaticListNode) = 1
Base.firstindex(x::StaticListEnd) = 0

next(x::StaticListNode) = x.next
next(x::StaticListEnd) = nothing
value(x::StaticListNode) = x.value
value(x::StaticListEnd) = nothing

function Base.getindex(x::LinkedList, i::Int)
    n = 1
    for elem in x
        if n == i
            return elem
        end
        n += 1
    end
    throw(BoundsError(x, i))
end

Base.:(==)(x::StaticListEnd, y::StaticListEnd) = true
Base.:(==)(x::LinkedList, y::LinkedList) = (value(x) == value(y)) && (next(x) == next(y))

Base.map(f::Base.Callable, x::StaticListEnd) = x
function Base.map(f::Base.Callable, x::StaticListNode{T}) where T
    #we build the new list from backwards...
    first = f(value(x))
    common_type = typeof(first) <: T ? T : typeof(first)
    first_node = StaticListNode(first, StaticListEnd{common_type}())
    for elem in next(x)
        first_node = StaticListNode(f(elem), first_node)
    end
    return reverse(first_node)
end

function Base.filter(f::Function, x::StaticListNode{T}) where T
    #Only join unto change if bool is true
    bnode = StaticListEnd{T}()
    for elem in x
        if f(elem)
            bnode = StaticListNode(elem, bnode)
        end
    end
    reverse(bnode)
end

#common interface
Base.eachindex(x::LinkedList) = Base.OneTo(length(x))
function Base.collect(x::LinkedList{T}) where T
    L = length(x)
    output = Vector{T}(undef, L)
    for (i, elem) in enumerate(x)
        output[i] = elem
    end
    return output
end

#Mutable simply linked list
#----------------------------------------------------


