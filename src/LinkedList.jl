#similar logic used in the Datastructures.jl packae...

abstract type SimpleLinkedList{T} end

struct EndNode{T} <: SimpleLinkedList{T}
end

struct SimpleLinkNode{T} <: SimpleLinkedList{T}
    value::T
    next::SimpleLinkedList{T}
end

SimpleLinkNode(x::T, next::SimpleLinkedList{T}) where T = SimpleLinkNode{T}(x, next)
SimpleLinkNode(x::T) where T = SimpleLinkNode(x, EndNode(T))
EndNode(x::T) where T = EndNode{T}()

SimpleLinkedList() = EndNode{Nothing}()

function SimpleLinkedList(x::T...) where T
    l = EndNode{T}()
    for i in length(x):-1:1
        l = SimpleLinkNode(x[i], l)
    end
    #return first node
    return l
end

function Base.length(x::SimpleLinkedList)
    le = 0
    for i in x
        le += 1
    end
    return le
end

Base.eltype(x::SimpleLinkedList{T}) where T = T

#empty iterator
Base.iterate(x::SimpleLinkedList, ::EndNode) = nothing

#iterator for non-end nodes
function Base.iterate(x::SimpleLinkedList, state::SimpleLinkNode = x)
    return x.value, x.next
end

Base.:(==)(x::EndNode, y::EndNode) = true
Base.:(==)(x::SimpleLinkNode, y::SimpleLinkNode) = (x.value == y.value) && (x.next == y.next)
function Base.Vector(x::SimpleLinkNode) 
    T = eltype(x)
    N = length(x)
    res = T[]
    sizehint!(res,N)
    for elem in x
        push!(res, elem.value)
    end
    return res
end

#is in-place reveral possible?
function Base.reverse(x::SimpleLinkedList{T}) where T
    
    node = EndNode(T)

    for elem in x
        node = SimpleLinkNode(elem, node)
    end
    return node
end
#not quite a push operator
function insert!(x::SimpleLinkNode{T}, y::T) where T
    nextnode = x.next
    x.next = SimpleLinkNode(y, nextnode)
    return nothing
end

#Doubly-linked (circular) lists

