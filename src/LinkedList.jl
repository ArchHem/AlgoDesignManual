#similar logic used in the Datastructures.jl packae...

abstract type SimpleLinkedList{T} end

struct EndNode{T} <: SimpleLinkedList{T}
end

struct SimpleLinkNode{T} <: SimpleLinkedList{T}
    value::T
    next::SimpleLinkedList{T}
end

SimpleLinkNode(x::T, next::SimpleLinkedList{T}) where T = SimpleLinkNode{T}(x, next)
EndNode(T) = EndNode{T}()

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
    return state.value, state.next
end

function Base.collect(x::SimpleLinkNode) 
    T = eltype(x)
    N = length(x)
    res = T[]
    sizehint!(res,N)
    for elem in x
        push!(res, elem)
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

#Doubly-linked (circular) lists

