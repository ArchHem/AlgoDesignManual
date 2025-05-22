#similar logic used in the Datastructures.jl packae...
abstract type AbstractList{T} end
abstract type LinkedList{T} <: AbstractList{T} end
abstract type StaticLinkedList{T} <: LinkedList{T} end
abstract type MLinkedList{T} <: LinkedList{T} end

Base.eltype(x::AbstractList{T}) where T = T
Base.ndims(::AbstractList{T}) where T = 1
Base.size(x::AbstractList{T}) where T = (length(x),)
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
    value(state), next(state)
end

Base.lastindex(x::LinkedList) = length(x)
Base.firstindex(x::LinkedList) = 1
Base.firstindex(x::StaticListEnd) = 0

next(x::StaticListNode) = x.next
next(x::StaticListEnd) = nothing
value(x::StaticListNode) = x.value
value(x::StaticListEnd) = nothing

function Base.getindex(x::LinkedList, i::Int)
    if i<1
        throw(BoundsError(x, i))
    end
    n = 1
    for elem in x
        if n == i
            return elem
        end
        n += 1
    end
    throw(BoundsError(x, i))
end

Base.:(==)(x::StaticListEnd{T}, y::StaticListEnd{Z}) where {T,Z} = true
Base.:(==)(x::LinkedList{T}, y::LinkedList{Z}) where {T,Z} = (value(x) == value(y)) && (next(x) == next(y))

Base.map(f::Base.Callable, x::StaticListEnd) = x
function Base.map(f::Base.Callable, x::StaticListNode...)
    #we build the new list from backwards...
    first = f(value.(x)...)
    T = promote_type(eltype.(x)...)
    common_type = typeof(first) <: T ? T : typeof(first)
    first_node = StaticListNode(first, StaticListEnd{common_type}())
    nextnodes = next.(x)
    for elems in zip(nextnodes...)
        first_node = StaticListNode(f(elems...), first_node)
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

#broadcast machinery as fallback
Base.Vector(x::LinkedList{T}) where T = collect(x)
Base.promote_rule(::Type{<:StaticListNode{T}},::Type{<:StaticListNode{Z}}) where {T, Z} = StaticListNode{promote_type(T,Z)}
Base.promote_rule(::Type{<:StaticListEnd{T}},::Type{<:StaticListEnd{Z}}) where {T, Z} = StaticListEnd{promote_type(T,Z)}
Base.promote_rule(::Type{<:LinkedList{T}},::Type{<:Vector{S}}) where {T, S} = Vector{promote_type(T,S)}

Base.Broadcast.broadcastable(x::StaticListNode) = x

struct SLLStyle <: Base.Broadcast.BroadcastStyle end

Base.Broadcast.BroadcastStyle(::Type{<:StaticListNode}) = SLLStyle()
#Promote broadcast to our style...
Base.Broadcast.BroadcastStyle(::SLLStyle, ::Base.Broadcast.DefaultArrayStyle{0}) = SLLStyle()
Base.Broadcast.BroadcastStyle(::SLLStyle, ::Base.Broadcast.DefaultArrayStyle{M}) where {M} = Base.Broadcast.DefaultArrayStyle{M}()


function Base.Broadcast.materialize(B::Base.Broadcast.Broadcasted{SLLStyle})
    flat = Base.Broadcast.flatten(B)
    args = flat.args
    f = flat.f
    primdata = map(a -> a isa StaticListNode ? value(a) : a, args)
    listypes = eltype.(filter(x->isa(x,StaticListNode), args))
    firstres = f(primdata...)
    urtype = promote_type(listypes...)
    otype = typeof(firstres)
    ftype = otype <: urtype ? urtype : otype
    datas = map(a -> a isa StaticListNode ? a : Iterators.repeated(a), args)
    result = StaticListEnd{ftype}()
    for elems in zip(datas...)
        result = StaticListNode{ftype}(f(elems...), result)
    end

    return reverse(result)
end
#Mutable simply linked list
#----------------------------------------------------

mutable struct MListNode{T} <: MLinkedList{T}
    value::T
    next::MLinkedList{T}
end

mutable struct MListEnd{T} <: MLinkedList{T}
end

function MListEnd(x::T) where T
    return MListEnd{T}()
end

function MListNode(x::T) where T
    return MListNode{T}(x, MListEnd{T}())
end

function MListNode(x::T, y::MLinkedList{T}) where T
    return MListNode{T}(x, y)
end

function MListNode(x...)
    T = promote_type(typeof.(x)...)
    node = MListNode(convert(T,x[end]))
    for i in (length(x)-1):-1:1
        node = MListNode{T}(convert(T,x[i]), node)
    end
    return node
end

function Base.reverse(x::MListNode{T}) where T
    currbegin = MListEnd{T}()
    for elem in x
        currbegin = MListNode(elem, currbegin)
    end
    return currbegin
end

function Base.reverse(x::MListEnd{T}) where T
    return x
end

function Base.reverse!(l::MListNode{T}) where T
    prev = MListEnd{T}()
    current = l
    while current isa MListNode
        next_node = current.next #sore next before modifying current
        current.next = prev
        prev = current
        current = next_node
    end
    return prev
end

function Base.reverse!(l::MListEnd{T}) where T
    return l
end

Base.iterate(l::MLinkedList, ::MListEnd) = nothing
function Base.iterate(l::MLinkedList, state::MListNode = l)
    value(state), next(state)
end

function Base.copy(x::MListEnd{T}) where T
    return MListEnd{T}()
end

function Base.copy(x::MListNode{T}) where T
    return MListNode(x.value, copy(x.next))
end


Base.length(x::MListNode) = begin
    n = 0
    for elem in x
        n +=1
    end
    return n
end

Base.length(x::MListEnd) = begin
    return 0
end

next(x::MListNode) = x.next
next(x::MListEnd) = nothing
value(x::MListNode) = x.value
value(x::MListEnd) = nothing

Base.firstindex(x::MListEnd) = 0

Base.:(==)(x::MListEnd{T}, y::MListEnd{Z}) where {T,Z} = true
Base.:(==)(x::MLinkedList{T}, y::MLinkedList{Z}) where {T,Z} = (value(x) == value(y)) && (next(x) == next(y))

Base.map(f::Base.Callable, x::MListEnd) = x

#recycle getindex logic
function Base.setindex!(x::MListNode{T}, val::T, i::Int) where T
    if i <= 0
        throw(BoundsError(x, i))
    end
    n = 1
    current = x
    while current isa MListNode
        if n == i
            current.value = val
            return nothing
        end
        n += 1
        current = current.next
    end
    throw(BoundsError(x, i))
end

function Base.setindex!(x::MListEnd{T}, val::T, i::Int) where T
    throw(BoundsError(x, i))
end

function Base.map(f::Base.Callable, x::MListNode...)
    first = f(value.(x)...)
    T = promote_type(eltype.(x)...)
    common_type = typeof(first) <: T ? T : typeof(first)
    first_node = MListNode(first, MListEnd{common_type}())
    nextnodes = next.(x)
    for elems in zip(nextnodes...)
        first_node = MListNode(f(elems...), first_node)
    end
    return reverse(first_node)
end

function Base.map!(f::Base.Callable, dest::MListNode{Z}, x::MListNode...) where Z
    first = f(value.(x)...)
    T = promote_type(eltype.(x)...)
    common_type = typeof(first) <: T ? T : typeof(first)
    if !(common_type <: Z)
        throw(TypeError(:map!,
                        "element type mismatch: cannot assign promoted input type to destination list's element type",
                        common_type, T))
    end
    primal = dest
    to_iterate = dest
    for elems in zip(x...)
        to_iterate = MListNode(f(elems...), first_node)
    end
    return primal
end

function Base.filter(f::Function, x::MListNode{T}) where T
    bnode = MListEnd{T}()
    for elem in x
        if f(elem)
            bnode = MListNode(elem, bnode)
        end
    end
    reverse(bnode)
end

function popnext!(x::MListNode{T}) where T
    next = next(x)
    nextval = value(x)
    next_next = next(next)
    if next isa MListEnd
        throw(BoundsError(x, 2))
    end
    x.next = next_next
    next.next = MListEnd{T}()
    return nextval
end

function insertnext!(x::MListNode{T}, y::MListNode{Z}) where {T,Z}
    next_x = x.next
    x.next = y
    y.next = next_x
    return x
end

function insertfull!(x::MListNode{T}, y::MListNode{Z}) where {T,Z}
    next_x = x.next
    x.next = y
    #find end of y
    y_end = y
    while next(y_end) isa MListNode
        y_end = next(y_end)
    end
    y_end.next = next_x
    return x
end

function cat!(x::MListNode{T}, y::MListNode{Z}) where {T,Z}
    #iterate to the end of x
    x_end = x
    while next(x_end) isa MListNode
        x_end = next(x_end)
    end
    x_end.next = y
    return x
end

Base.promote_rule(::Type{<:MListNode{T}},::Type{<:MListNode{Z}}) where {T, Z} = MListNode{promote_type(T,Z)}
Base.promote_rule(::Type{<:MListEnd{T}},::Type{<:MListEnd{Z}}) where {T, Z} = MListEnd{promote_type(T,Z)}

struct MLLStyle <: Base.Broadcast.BroadcastStyle end
Base.Broadcast.BroadcastStyle(::Type{<:MListNode}) = MLLStyle()
Base.Broadcast.BroadcastStyle(::MLLStyle, ::Base.Broadcast.DefaultArrayStyle{0}) = MLLStyle()
Base.Broadcast.BroadcastStyle(::MLLStyle, ::Base.Broadcast.DefaultArrayStyle{M}) where {M} = Base.Broadcast.DefaultArrayStyle{M}()

function Base.Broadcast.materialize(B::Base.Broadcast.Broadcasted{MLLStyle})
    flat = Base.Broadcast.flatten(B)
    args = flat.args
    f = flat.f
    primdata = map(a -> a isa MListNode ? value(a) : a, args)
    listypes = eltype.(filter(x->isa(x,MListNode), args))
    firstres = f(primdata...)
    urtype = promote_type(listypes...)
    otype = typeof(firstres)
    ftype = otype <: urtype ? urtype : otype
    datas = map(a -> a isa MListNode ? a : Iterators.repeated(a), args)
    result = MListEnd{ftype}()
    for elems in zip(datas...)
        result = MListNode{ftype}(f(elems...), result)
    end
    return reverse(result)
end




