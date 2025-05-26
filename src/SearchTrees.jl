module SearchTrees

#Based on Chapter 1. a static """dictionary""" using a sorted list. This could be extended to be mutable: but pointer based structs are better there.

#There is surprisngly little info on the AbstractDict type. As such, we do not subtype this.
#Static BST, using a sorted list under the hood
abstract type SearchTree{T,Z} end
struct StaticBST{T, Z} <: SearchTree{T,Z}
    keys::Vector{T} #sorted array
    values::Vector{Z}
    function StaticBST{T, Z}(keys::Vector{T}, values::Vector{Z}) where {T,Z}
        @assert issorted(keys) "Internal error: keys must be sorted!"
        @assert length(Set(keys)) == length(keys) "Internal error: keys must be unique!"
        new(keys, values)
    end
end

#Elements of x must have a valid less-then implemented
#x is a sorted array
function BinarySearch(x::AbstractVector{T}, key::T, left = firstindex(x), right = lastindex(x)) where T
    if IndexStyle(x) != IndexLinear()
        throw(ErrorException("Binary search search only supported on arrays with linear indeces"))
    end
    while left <= right
        midindex = left + div(right - left, 2)
        #this picks the "higher" midpoint
        mid = x[midindex]
        if mid == key
            return midindex
        elseif mid < key
            #move to second half
            left = midindex + 1
        else
            right = midindex - 1
        end
    end
    return nothing
end

function StaticBST(keys::AbstractArray{T}, values::AbstractArray{Z}) where {T,Z}
    if length(keys) != length(values)
        throw(DimensionMismatch("Keys and values must have the same length."))
    end
    if length(Set(keys)) != length(keys)
        throw(ArgumentError("Keys must not contain duplicates."))
    end
    p = sortperm(keys)
    #indexing implicitly copies.
    return StaticBST{T, Z}(Vector{T}(keys[p]), Vector{Z}(values[p]))
end

Base.keys(x::StaticBST) = x.keys
Base.values(x::StaticBST) = x.values
function Base.haskey(x::StaticBST, key)
    index = BinarySearch(keys(x), key)
    if isnothing(index)
        return false
    end
    return true
end

function Base.getindex(x::StaticBST, key)
    index = BinarySearch(keys(x), key)
    if isnothing(index)
        throw(KeyError(key))
    end
    return values(x)[index] 
end

function Base.setindex!(x::StaticBST, a, key)
    index = BinarySearch(keys(x), key)
    if isnothing(index)
        throw(KeyError(key))
    end
    x.values[index] = a
    return x
end

Base.length(x::StaticBST) = length(values(x))
Base.isempty(x::StaticBST) = isempty(values(x))

#first gets called
function Base.iterate(x::StaticBST{T, Z}) where {T,Z}
    if isempty(x)
        return nothing
    end
    i = 1
    return (x.keys[i] => x.values[i], i + 1)
end


function Base.iterate(x::StaticBST{T,Z}, state) where {T,Z}
    if state > length(x)
        return nothing
    end
    
    return (x.keys[state] => x.values[state], state + 1)
end

Base.length(x::StaticBST) = length(values(x))
Base.isempty(x::StaticBST) = isempty(values(x))

#first gets called
function Base.iterate(x::StaticBST{T, Z}) where {T,Z}
    if isempty(x)
        return nothing
    end
    i = 1
    return (x.keys[i] => x.values[i], i + 1)
end


function Base.iterate(x::StaticBST{T,Z}, state) where {T,Z}
    if state > length(x)
        return nothing
    end
    return (x.keys[state] => x.values[state], state + 1)
end

Base.keytype(x::StaticBST{T,Z}) where {T,Z} = T
Base.valtype(x::StaticBST{T,Z}) where {T,Z} = Z

#AVL trees
#------------------------------------------------------
abstract type AVLTree{T,Z} <: SearchTree{T,Z} end

mutable struct AVLNode{T,Z} <: AVLTree{T,Z}
    key::T
    value::Z
    left::AVLTree{T,Z}
    right::AVLTree{T,Z}
    height::Int64
end

struct AVLEnd{T, Z} <: AVLTree{T,Z}
end

AVLNode(x::T, y::Z, left::AVLTree{T,Z}, right::AVLTree{T,Z}, height) where {T, Z} = AVLNode{T,Z}(x, y, left, right, height)
AVLNode(x::T, y::Z) where {T,Z} = AVLNode{T,Z}(x, y, AVLEnd{T,Z}(), AVLEnd{T,Z}(), 1)

isleaf(x::AVLNode) = false
isleaf(x::AVLEnd) = true
left(x::AVLNode) = x.left
right(x::AVLNode) = x.right
left(x::AVLEnd) = nothing
right(x::AVLEnd) = nothing
height(x::AVLNode) = x.height
height(x::AVLEnd) = 0
key(x::AVLNode) = x.key
value(x::AVLNode) = x.value
setheight!(x::AVLNode, h::Int64) = begin x.height = h 
    return nothing end
setheight!(x::AVLNode) = begin x.height = max(height(x.left), height(x.right)) + 1 
    return nothing end
loadbalance(x::AVLNode) = height(x.left) - height(x.right)
isbalanced(x::AVLNode) = loadbalance(x) in [-1, 0, 1]

Base.keytype(x::AVLTree{T,Z}) where {T,Z} = T
Base.valtype(x::AVLTree{T,Z}) where {T,Z} = Z

function _DFS(x::AVLNode{T,Z}) where {T,Z}
    lstack = AVLNode{T,Z}[]
    keys = T[]
    values = Z[]
    
    current = x
    while !isleaf(current) || !isempty(lstack)
        while !isleaf(current)
            push!(lstack, current)
            current = left(current)
        end
        currnode = pop!(lstack)
        push!(keys, key(currnode))
        push!(values, value(currnode))
        current = right(currnode)
    end
    
    return keys, values
end

#I.e. this will go like so:
#        2
#      1   3
# [1 2 3]
#i.e. keys are returned in sorted order

#initial iterator
function Base.iterate(x::AVLNode{T,Z}) where {T,Z}
    stack = AVLNode{T,Z}[]
    current = x
    while !isleaf(current)
        push!(stack, current)
        current = current.left
    end
    returnnode = pop!(stack)
    return (key(returnnode) => value(returnnode), (stack, right(returnnode)))
end

function Base.iterate(x::AVLNode{T,Z}, state) where {T,Z}
    #this is not yet an end-node, but we already have a stack.
    #Proceed with dfs.
    
    stack, prevright = state
    current = prevright
    while !isleaf(current)
        push!(stack, current)
        current = left(current)
    end

    #pop node and its key/value
    if isempty(stack)
        return nothing
    else
        returnode = pop!(stack)
        return (key(returnode) => value(returnode), (stack, right(returnode)))
    end
end

Base.iterate(x::AVLEnd) = nothing

Base.keys(x::AVLNode) = collect(k.first for k in x)
Base.values(x::AVLNode) = collect(k.second for k in x)
Base.keys(x::AVLEnd{T,Z}) where {T,Z} = T[]
Base.values(x::AVLEnd{T,Z}) where {T,Z} = Z[]

function rotate_left!(x::AVLNode)
    new_root = right(x)
    #rotate
    new_right = left(new_root)
    new_root.left = x
    x.right = new_right
    setheight!(x)
    setheight!(new_root)
    
    return new_root
end

function rotate_right!(x::AVLNode)
    new_root = left(x)
    #rotate
    new_left = right(new_root)
    new_root.right = x
    x.left = new_left
    setheight!(x)
    setheight!(new_root)
    
    return new_root
end

function Base.getindex(x::AVLNode{T,Z}, i::T) where {T,Z}
    #traversal
    current = x
    while !isleaf(current)
        if key(current) == i
            return value(current)
        elseif key(current) < i
            current = current.right
        else
            current = current.left
        end
    end
    throw(KeyError(i))
end

function Base.setindex!(x::AVLNode{T,Z}, k::Z, i::T) where {T,Z}
    #traversal
    current = x
    while !isleaf(current)
        if key(current) == i
            current.value = k
            return nothing
        elseif key(current) < i
            current = current.right
        else
            current = current.left
        end
    end
    throw(KeyError(i))
end

function Base.haskey(x::AVLNode{T,Z}, i::T) where {T,Z}
    #traversal
    current = x
    while !isleaf(current)
        if key(current) == i
            return true
        elseif key(current) < i
            current = current.right
        else
            current = current.left
        end
    end
    return false
end

export StaticBST, AVLTree, AVLNode, AVLEnd, SearchTree
end