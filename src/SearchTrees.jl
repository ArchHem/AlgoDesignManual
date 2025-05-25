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
    height::Int64
end

AVLEnd{T,Z}() where {T,Z} = AVLEnd{T,Z}(0)
AVLNode(x::T, y::Z, left::AVLTree{T,Z}, right::AVLTree{T,Z}, height = 1) = AVLNode{T,Z}(x, y, left, right, height)

isleaf(x::AVLNode) = false
isleaf(x::AVLEnd) = true
left(x::AVLNode) = x.left
right(x::AVLNode) = x.right
left(x::AVLEnd) = nothing
right(x::AVLEnd) = nothing
height(x::AVLTree) = x.height
key(x::AVLNode) = x.key
value(x::AVLNode) = x.value
setheight!(x::AVLNode, h::Int64) = begin x.height = h end

Base.keytype(x::AVLTree{T,Z}) where {T,Z} = T
Base.valtype(x::AVLTree{T,Z}) where {T,Z} = Z



export StaticBST, AVLTree, AVLNode, AVLEnd, SearchTree
end